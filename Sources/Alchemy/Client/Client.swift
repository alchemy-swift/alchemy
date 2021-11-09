import AsyncHTTPClient

public final class Client: RequestBuilder, Service {
    private let httpClient = HTTPClient(eventLoopGroupProvider: .shared(Loop.group))
    
    // MARK: - Testing

    private var stubs: [String: ClientResponseStub]? = nil
    var stubbedRequests: [HTTPClient.Request] = []
    
    public func stub(_ stubs: [String: ClientResponseStub] = [:]) {
        self.stubs = stubs
    }
    
    public static func stub(_ stubs: [String: ClientResponseStub] = [:]) {
        Client.default.stub(stubs)
    }
    
    // MARK: - RequestBuilder
    
    public typealias Res = ClientResponse
    
    public var builder: ClientRequestBuilder {
        ClientRequestBuilder(httpClient: httpClient, stubs: stubs) { [weak self] request in
            self?.stubbedRequests.append(request)
        }
    }
    
    // MARK: - Service
    
    public func shutdown() throws {
        try httpClient.syncShutdown()
    }
}

public struct ClientResponseStub {
    var status: HTTPResponseStatus = .ok
    var headers: HTTPHeaders = [:]
    var body: ByteBuffer? = nil
    
    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], body: ByteBuffer? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

public final class ClientRequestBuilder: RequestBuilder {
    private let httpClient: HTTPClient
    private var queries: [String: String] = [:]
    private var headers: [(String, String)] = []
    private var createBody: (() throws -> ByteBuffer?)?
    
    private let stubs: [String: ClientResponseStub]?
    private let didStub: ((HTTPClient.Request) -> Void)?
    
    public var builder: ClientRequestBuilder { self }
    
    init(httpClient: HTTPClient, stubs: [String: ClientResponseStub]?, didStub: ((HTTPClient.Request) -> Void)? = nil) {
        self.httpClient = httpClient
        self.stubs = stubs
        self.didStub = didStub
    }

    public func withHeader(_ header: String, value: String) -> ClientRequestBuilder {
        headers.append((header, value))
        return self
    }
    
    public func withQuery(_ query: String, value: String) -> ClientRequestBuilder {
        queries[query] = value
        return self
    }
    
    public func withBody(_ createBody: @escaping () throws -> ByteBuffer?) -> ClientRequestBuilder {
        self.createBody = createBody
        return self
    }
    
    public func request(_ method: HTTPMethod, _ host: String) async throws -> ClientResponse {
        let buffer = try createBody?()
        let body = buffer.map { HTTPClient.Body.byteBuffer($0) }
        let headers = HTTPHeaders(headers)
        let req = try HTTPClient.Request(
            url: host + queryString(for: host),
            method: method,
            headers: headers,
            body: body,
            tlsConfiguration: nil
        )
        
        if stubs != nil {
            didStub?(req)
            return stubFor(req)
        } else {
            return ClientResponse(request: req, response: try await httpClient.execute(request: req).get())
        }
    }
    
    private func stubFor(_ req: HTTPClient.Request) -> ClientResponse {
        for (pattern, stub) in stubs ?? [:] {
            if req.matchesFakePattern(pattern) {
                return ClientResponse(
                    request: req,
                    response: HTTPClient.Response(
                        host: req.host,
                        status: stub.status,
                        version: .http1_1,
                        headers: stub.headers,
                        body: stub.body))
            }
        }
        
        return ClientResponse(
            request: req,
            response: HTTPClient.Response(
                host: req.host,
                status: .ok,
                version: .http1_1,
                headers: [:],
                body: nil))
    }
    
    private func queryString(for path: String) -> String {
        guard queries.count > 0 else {
            return ""
        }
        
        let questionMark = path.contains("?") ? "&" : "?"
        return questionMark + queries.map { "\($0)=\($1.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")" }.joined(separator: "&")
    }
}

extension HTTPClient.Request {
    fileprivate func matchesFakePattern(_ pattern: String) -> Bool {
        let wildcard = "*"
        let cleanedPattern = pattern.droppingPrefix("https://").droppingPrefix("http://")
        if cleanedPattern == wildcard {
            return true
        } else if var host = url.host {
            if let port = url.port {
                host += ":\(port)"
            }
            
            let fullPath = host + url.path
            for (hostChar, patternChar) in zip(fullPath, pattern) {
                if String(patternChar) == wildcard {
                    return true
                } else if hostChar == patternChar {
                    continue
                } else {
                    return false
                }
            }
            
            return fullPath.count == pattern.count
        } else {
            return false
        }
    }
}
