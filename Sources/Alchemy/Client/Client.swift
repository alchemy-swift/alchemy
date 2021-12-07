import AsyncHTTPClient
import NIOCore
import NIOHTTP1

/// A convenient client for making http requests from your app. Backed by
/// `AsyncHTTPClient`.
///
/// The `Http` alias can be used to access your app's default client.
///
///     Http.get("https://swift.org")
///
/// See `ClientProvider` for the request builder interface.
public final class Client: ClientProvider, Service {
    /// A type for making http requests with a `Client`. Supports static or
    /// streamed content.
    public struct Request {
        /// How long until this request times out.
        public var timeout: TimeAmount? = nil
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
    public struct Response {
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
        
        /// Create a stubbed response with the given info. It will be returned
        /// for any incoming request that matches the stub pattern.
        public static func stub(
            _ status: HTTPResponseStatus = .ok,
            version: HTTPVersion = .http1_1,
            headers: HTTPHeaders = [:],
            body: ByteContent? = nil
        ) -> Client.Response {
            Client.Response(request: .init(), host: "", status: status, version: version, headers: headers, body: body)
        }
    }
    
    /// Helper for building http requests.
    public final class Builder: RequestBuilder {
        /// A request made with this builder returns a `Client.Response`.
        public typealias Res = Response
        
        /// Build using this builder.
        public var builder: Builder { self }
        /// The request being built.
        public var partialRequest: Request = .init()
        
        private let execute: (Request, HTTPClient.Configuration?) async throws -> Client.Response
        private var configOverride: HTTPClient.Configuration? = nil
        
        fileprivate init(execute: @escaping (Request, HTTPClient.Configuration?) async throws -> Client.Response) {
            self.execute = execute
        }
        
        /// Execute the built request using the backing client.
        ///
        /// - Returns: The resulting response.
        public func execute() async throws -> Response {
            try await execute(partialRequest, configOverride)
        }
        
        /// Sets an `HTTPClient.Configuration` for this request only. See the
        /// `swift-server/async-http-client` package for configuration
        /// options.
        public func withClientConfig(_ config: HTTPClient.Configuration) -> Builder {
            self.configOverride = config
            return self
        }
        
        /// Timeout if the request doesn't finish in the given time amount.
        public func withTimeout(_ timeout: TimeAmount) -> Builder {
            with { $0.timeout = timeout }
        }
    }
    
    /// A request made with this builder returns a `Client.Response`.
    public typealias Res = Response
    
    /// The underlying `AsyncHTTPClient.HTTPClient` used for making requests.
    public var httpClient: HTTPClient
    /// The builder to defer to when building requests.
    public var builder: Builder { Builder(execute: execute) }
    
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
    func execute(req: Request, config: HTTPClient.Configuration?) async throws -> Response {
        guard stubs == nil else {
            return stubFor(req)
        }
        
        let deadline: NIODeadline? = req.timeout.map { .now() + $0 }
        let httpClientOverride = config.map { HTTPClient(eventLoopGroupProvider: .shared(httpClient.eventLoopGroup), configuration: $0) }
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

public class ResponseDelegate: HTTPClientResponseDelegate {
    public typealias Response = Void

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

    public init(request: Client.Request, promise: EventLoopPromise<Client.Response>) {
        self.request = request
        self.responsePromise = promise
    }

    public func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
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

    public func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ part: ByteBuffer) -> EventLoopFuture<Void> {
        switch self.state {
        case .idle:
            preconditionFailure("no head received before body")
        case .head(let head):
            self.state = .body(head, part)
            return task.eventLoop.makeSucceededFuture(())
        case .body(let head, let body):
            let stream = Stream<ByteBuffer>(eventLoop: task.eventLoop)
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

    public func didReceiveError(task: HTTPClient.Task<Response>, _ error: Error) {
        self.state = .error(error)
    }

    public func didFinishRequest(task: HTTPClient.Task<Response>) throws {
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
            throw error
        }
    }
}
