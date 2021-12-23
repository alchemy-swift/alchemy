import AsyncHTTPClient
import Hummingbird
import NIOCore
import NIOHTTP1

/// A convenient client for making http requests from your app. Backed by
/// `AsyncHTTPClient`.
///
/// The `Http` alias can be used to access your app's default client.
///
///     let response = try await Http.get("https://swift.org")
///
/// See `ClientProvider` for the request builder interface.
public final class Client: Service {
    /// A type for making http requests with a `Client`. Supports static or
    /// streamed content.
    public struct Request {
        /// The url components.
        public var urlComponents: URLComponents = URLComponents()
        /// The request method.
        public var method: HTTPMethod = .GET
        /// Any headers for this request.
        public var headers: HTTPHeaders = [:]
        /// The body of this request, either a static buffer or byte stream.
        public var body: ByteContent? = nil
        /// The url of this request.
        public var url: URL { urlComponents.url ?? URL(string: "/")! }
        /// Remote host, resolved from `URL`.
        public var host: String { urlComponents.url?.host ?? "" }
        /// How long until this request times out.
        public var timeout: TimeAmount? = nil
        /// Custom config override when making this request.
        public var config: HTTPClient.Configuration? = nil
        /// Allows for extending storage on this type.
        public var extensions = HBExtensions<Self>()
        
        public init(url: String = "", method: HTTPMethod = .GET, headers: HTTPHeaders = [:], body: ByteContent? = nil, timeout: TimeAmount? = nil) {
            self.urlComponents = URLComponents(string: url) ?? URLComponents()
            self.method = method
            self.headers = headers
            self.body = body
            self.timeout = timeout
        }
        
        /// The underlying `AsyncHTTPClient.HTTPClient.Request`.
        fileprivate var _request: HTTPClient.Request {
            get throws {
                guard let url = urlComponents.url else { throw HTTPClientError.invalidURL }
                let body: HTTPClient.Body? = {
                    switch self.body {
                    case .buffer(let buffer):
                        return .byteBuffer(buffer)
                    case .stream(let stream):
                        func writeStream(writer: HTTPClient.Body.StreamWriter) -> EventLoopFuture<Void> {
                            Loop.current.asyncSubmit {
                                try await stream.readAll {
                                    try await writer.write(.byteBuffer($0)).get()
                                }
                            }
                        }
                        
                        return .stream(length: headers.contentLength, writeStream)
                    case .none:
                        return nil
                    }
                }()
                
                return try HTTPClient.Request(url: url, method: method, headers: headers, body: body)
            }
        }
    }
    
    /// The response type of a request made with client. Supports static or
    /// streamed content.
    public struct Response: ResponseInspector {
        /// The request that resulted in this response
        public var request: Client.Request
        /// Remote host of the request.
        public var host: String
        /// Response HTTP status.
        public let status: HTTPResponseStatus
        /// Response HTTP version.
        public let version: HTTPVersion
        /// Reponse HTTP headers.
        public let headers: HTTPHeaders
        /// Response body.
        public var body: ByteContent?
        /// Allows for extending storage on this type.
        public var extensions = HBExtensions<Self>()
        
        /// Create a stubbed response with the given info. It will be returned
        /// for any incoming request that matches the stub pattern.
        public static func stub(
            _ status: HTTPResponseStatus = .ok,
            version: HTTPVersion = .http1_1,
            headers: HTTPHeaders = [:],
            body: ByteContent? = nil
        ) -> Client.Response {
            Client.Response(request: Request(url: ""), host: "", status: status, version: version, headers: headers, body: body)
        }
    }
    
    public struct Builder: RequestBuilder {
        public var client: Client
        public var urlComponents: URLComponents { get { request.urlComponents } set { request.urlComponents = newValue} }
        public var method: HTTPMethod { get { request.method } set { request.method = newValue} }
        public var headers: HTTPHeaders { get { request.headers } set { request.headers = newValue} }
        public var body: ByteContent? { get { request.body } set { request.body = newValue} }
        private var request: Client.Request
        
        init(client: Client) {
            self.client = client
            self.request = Request()
        }
        
        public func execute() async throws -> Client.Response {
            try await client.execute(req: request)
        }
        
        /// Sets an `HTTPClient.Configuration` for this request only. See the
        /// `swift-server/async-http-client` package for configuration
        /// options.
        public func withClientConfig(_ config: HTTPClient.Configuration) -> Builder {
            with { $0.request.config = config }
        }

        /// Timeout if the request doesn't finish in the given time amount.
        public func withTimeout(_ timeout: TimeAmount) -> Builder {
            with { $0.request.timeout = timeout }
        }
        
        /// Stub this client, causing it to respond to all incoming requests with a
        /// stub matching the request url or a default `200` stub.
        public func stub(_ stubs: [(String, Client.Response)] = []) {
            self.client.stubs = stubs
        }
    }
    
    /// The underlying `AsyncHTTPClient.HTTPClient` used for making requests.
    public var httpClient: HTTPClient
    private var stubWildcard: Character = "*"
    private var stubs: [(pattern: String, response: Response)]?
    private(set) var stubbedRequests: [Client.Request]
    
    /// Create a client backed by the given `AsyncHTTPClient` client. Defaults
    /// to a client using the default config and app `EventLoopGroup`.
    public init(httpClient: HTTPClient = HTTPClient(eventLoopGroupProvider: .shared(Loop.group))) {
        self.httpClient = httpClient
        self.stubs = nil
        self.stubbedRequests = []
    }
    
    public func builder() -> Builder {
        Builder(client: self)
    }
    
    /// Shut down the underlying http client.
    public func shutdown() throws {
        try httpClient.syncShutdown()
    }
    
    /// Stub this client, causing it to respond to all incoming requests with a
    /// stub matching the request url or a default `200` stub.
    public func stub(_ stubs: [(String, Client.Response)] = []) {
        self.stubs = stubs
    }
    
    /// Execute a request.
    ///
    /// - Parameters:
    ///   - req: The request to execute.
    ///   - config: A custom configuration for the client that will execute the
    ///     request
    /// - Returns: The request's response.
    private func execute(req: Request) async throws -> Response {
        guard stubs == nil else {
            return stubFor(req)
        }
        
        let deadline: NIODeadline? = req.timeout.map { .now() + $0 }
        let httpClientOverride = req.config.map { HTTPClient(eventLoopGroupProvider: .shared(httpClient.eventLoopGroup), configuration: $0) }
        defer { try? httpClientOverride?.syncShutdown() }
        let promise = Loop.group.next().makePromise(of: Response.self)
        _ = (httpClientOverride ?? httpClient)
            .execute(
                request: try req._request,
                delegate: ResponseDelegate(request: req, promise: promise),
                deadline: deadline,
                logger: Log.logger)
        return try await promise.futureResult.get()
    }
    
    private func stubFor(_ req: Request) -> Response {
        stubbedRequests.append(req)
        let match = stubs?.first { pattern, _ in doesPattern(pattern, match: req) }
        var stub: Client.Response = match?.response ?? .stub()
        stub.request = req
        stub.host = req.url.host ?? ""
        return stub
    }
    
    private func doesPattern(_ pattern: String, match request: Request) -> Bool {
        let requestUrl = [
            request.url.host,
            request.url.port.map { ":\($0)" },
            request.url.path,
        ]
            .compactMap { $0 }
            .joined()
        
        let patternUrl = pattern
            .droppingPrefix("https://")
            .droppingPrefix("http://")
        
        for (hostChar, patternChar) in zip(requestUrl, patternUrl) {
            guard patternChar != stubWildcard else { return true }
            guard hostChar == patternChar else { return false }
        }
        
        return requestUrl.count == patternUrl.count
    }
}

/// Converts an AsyncHTTPClient response into a `Client.Response`.
private class ResponseDelegate: HTTPClientResponseDelegate {
    typealias Response = Void

    enum State {
        case idle
        case head(HTTPResponseHead)
        case body(HTTPResponseHead, ByteBuffer)
        case stream(HTTPResponseHead, ByteStream)
        case error(Error)
    }

    private let request: Client.Request
    private let responsePromise: EventLoopPromise<Client.Response>
    private var state = State.idle

    init(request: Client.Request, promise: EventLoopPromise<Client.Response>) {
        self.request = request
        self.responsePromise = promise
    }

    func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        switch self.state {
        case .idle:
            self.state = .head(head)
            return task.eventLoop.makeSucceededFuture(())
        case .head:
            preconditionFailure("head already set")
        case .body:
            preconditionFailure("no head received before body")
        case .stream:
            preconditionFailure("no head received before body")
        case .error:
            return task.eventLoop.makeSucceededFuture(())
        }
    }

    var count = 0
    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ part: ByteBuffer) -> EventLoopFuture<Void> {
        switch self.state {
        case .idle:
            preconditionFailure("no head received before body")
        case .head(let head):
            self.state = .body(head, part)
            return task.eventLoop.makeSucceededFuture(())
        case .body(let head, let body):
            let stream = ByteStream(eventLoop: task.eventLoop)
            let response = Client.Response(request: request, host: request.host, status: head.status, version: head.version, headers: head.headers, body: .stream(stream))
            self.responsePromise.succeed(response)
            self.state = .stream(head, stream)

            // Write the previous part, followed by this part, to the stream.
            return stream._write(chunk: body).flatMap { stream._write(chunk: part) }
        case .stream(_, let stream):
            return stream._write(chunk: part)
        case .error:
            return task.eventLoop.makeSucceededFuture(())
        }
    }

    func didReceiveError(task: HTTPClient.Task<Response>, _ error: Error) {
        self.state = .error(error)
    }

    func didFinishRequest(task: HTTPClient.Task<Response>) throws {
        switch self.state {
        case .idle:
            preconditionFailure("no head received before end")
        case .head(let head):
            let response = Client.Response(request: request, host: request.host, status: head.status, version: head.version, headers: head.headers, body: nil)
            responsePromise.succeed(response)
        case .body(let head, let body):
            let response = Client.Response(request: request, host: request.host, status: head.status, version: head.version, headers: head.headers, body: .buffer(body))
            responsePromise.succeed(response)
        case .stream(_, let stream):
            _ = stream._write(chunk: nil)
        case .error(let error):
            responsePromise.fail(error)
        }
    }
}
