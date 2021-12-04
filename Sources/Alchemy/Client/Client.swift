import AsyncHTTPClient
import NIOCore
import Foundation

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
        /// The underlying `AsyncHTTPClient.HTTPClient.Request`.
        public var _request: HTTPClient.Request {
            get throws {
                guard let url = urlComponents.url else { throw HTTPClientError.invalidURL }
                return try HTTPClient.Request(url: url, method: method, headers: headers, body: {
                    switch body {
                    case .buffer(let buffer):
                        return .byteBuffer(buffer)
                    case .stream(let stream):
                        return .stream(length: headers.contentLength, { writer in
                            return Loop.current.asyncSubmit {
                                try await stream.write?({
                                    try await writer.write(.byteBuffer($0)).get()
                                })
                            }
                        })
                    case .none:
                        return nil
                    }
                }())
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
        public let body: ByteContent?
        
        /// Create a stubbed response with the given info. It will be returned
        /// for any incoming request that matches the stub pattern.
        public static func stub(_ status: HTTPResponseStatus = .ok, version: HTTPVersion = .http1_1, headers: HTTPHeaders = [:], body: ByteContent? = nil) -> Client.Response {
            Client.Response(request: .init(), host: "", status: status, version: version, headers: headers, body: body)
        }
    }
    
    /// Helper for building HTTPRequests.
    public final class Builder: RequestBuilder {
        /// A request made with this builder returns a `Client.Response`.
        public typealias Res = Response
        /// The request being build.
        public var partialRequest: Request = .init()
        /// Build using this builder.
        public var builder: Builder { self }
        
        private let execute: (Request, HTTPClient.Configuration?) async throws -> Client.Response
        private var configOverride: HTTPClient.Configuration? = nil
        
        fileprivate init(execute: @escaping (Request, HTTPClient.Configuration?) async throws -> Client.Response) {
            self.execute = execute
        }
        
        /// Execute the build request using the backing client.
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
        if stubs != nil {
            return stubFor(req)
        } else {
            let deadline: NIODeadline? = req.timeout.map { .now() + $0 }
            let httpClientOverride = config.map { HTTPClient(eventLoopGroupProvider: .shared(httpClient.eventLoopGroup), configuration: $0) }
            defer { try? httpClientOverride?.syncShutdown() }
            
            let client = httpClientOverride ?? httpClient
            let res = try await client.execute(request: req._request, deadline: deadline).get()
            return Client.Response(request: req, host: res.host, status: res.status, version: res.version, headers: res.headers, body: res.body.map { .buffer($0) })
        }
    }
    
    private func stubFor(_ req: Request) -> Response {
        stubbedRequests.append(req)
        let match = stubs?.first(where: { pattern, _ in doesPatternMatch(pattern, request: req) })
        var stub: Client.Response = match?.response ?? .stub()
        stub.request = req
        stub.host = req.url.host ?? ""
        return stub
    }
    
    private func doesPatternMatch(_ pattern: String, request: Request) -> Bool {
        let wildcard = "*"
        var cleanedPattern = pattern.droppingPrefix("https://").droppingPrefix("http://")
        cleanedPattern = String(cleanedPattern.split(separator: "?")[0])
        if cleanedPattern == wildcard {
            return true
        } else if var host = request.url.host {
            if let port = request.url.port {
                host += ":\(port)"
            }
            
            let fullPath = host + request.url.path
            for (hostChar, patternChar) in zip(fullPath, cleanedPattern) {
                if String(patternChar) == wildcard {
                    return true
                } else if hostChar == patternChar {
                    continue
                }
                
                return false
            }
            
            return fullPath.count == pattern.count
        }
        
        return false
    }
}
