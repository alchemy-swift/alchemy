import AsyncHTTPClient
import Foundation
import NIOCore
import NIOHTTP1

/// A convenient client for making http requests from your app. Backed by
/// `AsyncHTTPClient`.
///
/// The `Http` alias can be used to access your app's default client.
///
///     let response = try await Http.get("https://swift.org")
///
/// See `Client.Builder` for the request builder interface.
public final class Client {

    /// A type for making http requests with a `Client`. Supports static or
    /// streamed content.
    public struct Request {
        /// The url components.
        public var urlComponents: URLComponents = URLComponents()
        /// The request method.
        public var method: HTTPRequest.Method = .get
        /// Any headers for this request.
        public var headers: HTTPFields = [:]
        /// The body of this request, either a static buffer or byte stream.
        public var body: Bytes? = nil
        /// The url of this request.
        public var url: URL { urlComponents.url ?? URL(string: "/")! }
        /// Remote host, resolved from `URL`.
        public var host: String { urlComponents.host ?? "" }
        /// The path of this request.
        public var path: String { urlComponents.path }
        /// How long until this request times out.
        public var timeout: Duration? = nil
        /// Whether to stream the response. If false, the response body will be
        /// fully accumulated before returning.
        public var streamResponse: Bool = false
        /// Custom config override when making this request.
        public var config: HTTPClient.Configuration? = nil
        
        public init(url: String = "", method: HTTPRequest.Method = .get, headers: HTTPFields = [:], body: Bytes? = nil, timeout: Duration? = nil) {
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
                            Loop.asyncSubmit {
                                for try await chunk in stream {
                                    try await writer.write(.byteBuffer(chunk)).get()
                                }
                            }
                        }
                        
                        return .stream(length: headers.contentLength, writeStream)
                    case .none:
                        return nil
                    }
                }()
                
                return try HTTPClient.Request(
                    url: url,
                    method: HTTPMethod(rawValue: method.rawValue),
                    headers: headers.nioHeaders,
                    body: body
                )
            }
        }
    }
    
    /// The response type of a request made with client. Supports static or
    /// streamed content.
    public struct Response: ResponseInspector, ResponseConvertible {
        /// The request that resulted in this response
        public var request: Client.Request
        /// Remote host of the request.
        public var host: String
        /// Response HTTP status.
        public let status: HTTPResponse.Status
        /// Reponse HTTP headers.
        public let headers: HTTPFields
        /// Response body.
        public var body: Bytes?
        /// Allows for extending storage on this type.
        public var container = Container()
        
        /// Create a stubbed response with the given info. It will be returned
        /// for any incoming request that matches the stub pattern.
        public static func stub(
            _ status: HTTPResponse.Status = .ok,
            headers: HTTPFields = [:],
            body: Bytes? = nil
        ) -> Client.Response {
            Client.Response(request: Request(url: ""), host: "", status: status, headers: headers, body: body)
        }

        // MARK: Validation

        @discardableResult
        public func validateSuccessful() throws -> Self {
            guard isSuccessful else {
                throw ClientError(message: "The response code was not successful", request: request, response: self)
            }

            return self
        }

        // MARK: Body

        public func decode<D: Decodable>(_ type: D.Type = D.self, using decoder: HTTPDecoder = .json) throws -> D {
            guard let buffer = body?.buffer else {
                throw ClientError(message: "The response had no body to decode from.", request: request, response: self)
            }

            do {
                return try decoder.decodeBody(D.self, from: buffer, contentType: headers.contentType)
            } catch {
                throw ClientError(message: "Error decoding `\(D.self)`. \(error)", request: request, response: self)
            }
        }

        @discardableResult
        public mutating func collect() async throws -> Client.Response {
            self.body = (try await body?.collect()).map { .buffer($0) }
            return self
        }

        // MARK: ResponseConvertible
        
        public func response() async throws -> Alchemy.Response {
            Alchemy.Response(status: status, headers: headers, body: body)
        }
    }
    
    public struct Builder: RequestBuilder {
        public var client: Client
        public var urlComponents: URLComponents { get { clientRequest.urlComponents } set { clientRequest.urlComponents = newValue} }
        public var method: HTTPRequest.Method { get { clientRequest.method } set { clientRequest.method = newValue} }
        public var headers: HTTPFields { get { clientRequest.headers } set { clientRequest.headers = newValue} }
        public var body: Bytes? { get { clientRequest.body } set { clientRequest.body = newValue} }
        public private(set) var clientRequest: Client.Request

        init(client: Client) {
            self.client = client
            self.clientRequest = Request()
        }
        
        public func execute() async throws -> Client.Response {
            try await client.execute(req: clientRequest)
        }
        
        /// Sets an `HTTPClient.Configuration` for this request only. See the
        /// `swift-server/async-http-client` package for configuration
        /// options.
        public func withClientConfig(_ config: HTTPClient.Configuration) -> Builder {
            with { $0.clientRequest.config = config }
        }

        /// Timeout if the request doesn't finish in the given time amount.
        public func withTimeout(_ timeout: Duration) -> Builder {
            with { $0.clientRequest.timeout = timeout }
        }
        
        /// Allow the response to be streamed.
        public func withStream() -> Builder {
            with { $0.clientRequest.streamResponse = true }
        }
        
        /// Stub this builder's client, causing it to respond to all incoming
        /// requests with a stub matching the request url or a default `200`
        /// stub.
        public func stub(_ stubs: Stubs = [:]) {
            self.client.stubs = stubs
        }
        
        /// Stub this builder's client, causing it to respond to all incoming
        /// requests using the provided handler.
        public func stub(_ handler: @escaping Stubs.Handler) {
            self.client.stubs = Stubs(handler: handler)
        }
    }
    
    /// Represents stubbed responses for a client.
    public final class Stubs: ExpressibleByDictionaryLiteral {
        public typealias Handler = (Client.Request) -> Client.Response
        private typealias Patterns = [(pattern: String, response: Client.Response)]
        
        private enum Kind {
            case patterns(Patterns)
            case handler(Handler)
        }
        
        private static let wildcard: Character = "*"
        private let kind: Kind
        private(set) var stubbedRequests: [Client.Request] = []
        
        init(handler: @escaping Handler) {
            self.kind = .handler(handler)
        }
        
        public init(dictionaryLiteral elements: (String, Client.Response)...) {
            self.kind = .patterns(elements)
        }
        
        func response(for req: Request) -> Response {
            stubbedRequests.append(req)
            
            switch kind {
            case .patterns(let patterns):
                let match = patterns.first { pattern, _ in doesPattern(pattern, match: req) }
                var stub: Client.Response = match?.response ?? .stub()
                stub.request = req
                stub.host = req.url.host ?? ""
                return stub
            case .handler(let handler):
                return handler(req)
            }
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
                guard patternChar != Stubs.wildcard else { return true }
                guard hostChar == patternChar else { return false }
            }
            
            return requestUrl.count == patternUrl.count
        }
    }
    
    /// The underlying `AsyncHTTPClient.HTTPClient` used for making requests.
    public var httpClient: HTTPClient
    var stubs: Stubs?
    
    /// Create a client backed by the given `AsyncHTTPClient` client. Defaults
    /// to a client using the default config and app `EventLoopGroup`.
    public init(httpClient: HTTPClient = HTTPClient(eventLoopGroupProvider: .shared(LoopGroup))) {
        self.httpClient = httpClient
        self.stubs = nil
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
    @discardableResult
    public func stub(_ stubs: Stubs = [:]) -> Client {
        self.stubs = stubs
        return self
    }
    
    /// Stub this client, causing it to respond to all incoming requests using
    /// the provided handler.
    @discardableResult
    public func stub(_ handler: @escaping Stubs.Handler) -> Client {
        self.stubs = Stubs(handler: handler)
        return self
    }
    
    /// Execute a request.
    ///
    /// - Parameters:
    ///   - req: The request to execute.
    ///   - config: A custom configuration for the client that will execute the
    ///     request
    /// - Returns: The request's response.
    private func execute(req: Request) async throws -> Response {
        if let stubs = stubs {
            return stubs.response(for: req)
        } else {
            let deadline: NIODeadline? = req.timeout.map { .now() + .seconds(Int64($0.seconds)) }
            let httpClientOverride = req.config.map { HTTPClient(eventLoopGroupProvider: .shared(httpClient.eventLoopGroup), configuration: $0) }

            do {
                let _request = try req._request
                let loop = LoopGroup.next()
                let promise = loop.makePromise(of: Response.self)
                let delegate = ResponseDelegate(request: req, promise: promise, allowStreaming: req.streamResponse)
                let client = httpClientOverride ?? httpClient
                _ = client.execute(request: _request, delegate: delegate, eventLoop: .delegateAndChannel(on: loop), deadline: deadline, logger: Log)
                let response = try await promise.futureResult.get()
                try await httpClientOverride?.shutdown()
                return response
            } catch {
                try await httpClientOverride?.shutdown()
                throw error
            }
        }
    }
}

/// Converts an AsyncHTTPClient response into a `Client.Response`.
private class ResponseDelegate: HTTPClientResponseDelegate {
    typealias Response = Void

    enum State {
        case idle
        case head(HTTPResponseHead)
        case body(HTTPResponseHead, ByteBuffer)
        case stream(HTTPResponseHead, Bytes.Writer)
        case error(Error)
    }

    private let responsePromise: EventLoopPromise<Client.Response>
    private let request: Client.Request
    private let allowStreaming: Bool
    private var state = State.idle

    init(request: Client.Request, promise: EventLoopPromise<Client.Response>, allowStreaming: Bool) {
        self.request = request
        self.responsePromise = promise
        self.allowStreaming = allowStreaming
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

    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ part: ByteBuffer) -> EventLoopFuture<Void> {
        switch state {
        case .idle:
            preconditionFailure("no head received before body")
        case .head(let head):
            state = .body(head, part)
            return task.eventLoop.makeSucceededFuture(())
        case .body(let head, var body):
            if allowStreaming {
                // TODO: use this for defering
                let (stream, continuation) = AsyncStream.makeStream(of: ByteBuffer.self)
                let writer = Bytes.Writer(continuation: continuation)
                let status = HTTPResponse.Status.init(integerLiteral: Int(head.status.code))
                let headers = HTTPFields(head.headers, splitCookie: false)
                let response = Client.Response(
                    request: request,
                    host: request.host,
                    status: status,
                    headers: headers,
                    body: .stream(stream)
                )

                self.responsePromise.succeed(response)
                self.state = .stream(head, writer)

                // Write the previous part, followed by this part, to the stream.
                return Loop.submit {
                    writer.write(body)
                    writer.write(part)
                }
            } else {
                // The compiler can't prove that `self.state` is dead here (and it kinda isn't, there's
                // a cross-module call in the way) so we need to drop the original reference to `body` in
                // `self.state` or we'll get a CoW. To fix that we temporarily set the state to `.idle` (which
                // has no associated data). We'll fix it at the bottom of this block.
                state = .idle
                var part = part
                body.writeBuffer(&part)
                state = .body(head, body)
                return task.eventLoop.makeSucceededVoidFuture()
            }
        case .stream(_, let stream):
            return Loop.submit {
                stream.write(part)
            }
        case .error:
            return task.eventLoop.makeSucceededFuture(())
        }
    }

    func didReceiveError(task: HTTPClient.Task<Response>, _ error: Error) {
        state = .error(error)
        responsePromise.fail(error)
    }

    func didFinishRequest(task: HTTPClient.Task<Response>) throws {
        switch state {
        case .idle:
            preconditionFailure("no head received before end")
        case .head(let head):
            let status = HTTPResponse.Status.init(integerLiteral: Int(head.status.code))
            let headers = HTTPFields(head.headers, splitCookie: false)
            let response = Client.Response(request: request, host: request.host, status: status, headers: headers, body: nil)
            responsePromise.succeed(response)
        case .body(let head, let body):
            let status = HTTPResponse.Status.init(integerLiteral: Int(head.status.code))
            let headers = HTTPFields(head.headers, splitCookie: false)
            let response = Client.Response(request: request, host: request.host, status: status, headers: headers, body: .buffer(body))
            responsePromise.succeed(response)
        case .stream(_, let writer):
            writer.finish()
        case .error:
            break
        }
    }
}
