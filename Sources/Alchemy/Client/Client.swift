import AsyncHTTPClient

public final class Client: RequestBuilder, Service {
    public typealias Res = ClientResponse

    private let httpClient: HTTPClient
    private var stubs: [(String, ClientResponseStub)]?
    private(set) var stubbedRequests: [HTTPClient.Request]
    
    init() {
        self.httpClient = HTTPClient(eventLoopGroupProvider: .shared(Loop.group))
        self.stubs = nil
        self.stubbedRequests = []
    }
    
    public var builder: ClientRequestBuilder {
        ClientRequestBuilder(httpClient: httpClient, stubs: stubs) { [weak self] in
            self?.stubbedRequests.append($0)
        }
    }
    
    public func shutdown() throws {
        try httpClient.syncShutdown()
    }
    
    public func stub(_ stubs: [(String, ClientResponseStub)] = []) {
        self.stubs = stubs
    }
    
    public static func stub(_ stubs: [(String, ClientResponseStub)] = []) {
        Client.default.stub(stubs)
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
    private let stubs: [(String, ClientResponseStub)]?
    private let didStub: ((HTTPClient.Request) -> Void)?
    
    public var builder: ClientRequestBuilder { self }
    
    init(httpClient: HTTPClient, stubs: [(String, ClientResponseStub)]?, didStub: ((HTTPClient.Request) -> Void)? = nil) {
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
        
        guard stubs != nil else {
            return ClientResponse(request: req, response: try await httpClient.execute(request: req).get())
        }
        
        didStub?(req)
        return stubFor(req)
    }
    
    private func stubFor(_ req: HTTPClient.Request) -> ClientResponse {
        let stubs = stubs ?? []
        for (pattern, stub) in stubs where req.matchesFakePattern(pattern) {
            let res = HTTPClient.Response(host: req.host, status: stub.status, version: .http1_1, headers: stub.headers, body: stub.body)
            return ClientResponse(request: req, response: res)
        }
        
        let res = HTTPClient.Response(host: req.host, status: .ok, version: .http1_1, headers: [:], body: nil)
        return ClientResponse(request: req, response: res)
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
        var cleanedPattern = pattern.droppingPrefix("https://").droppingPrefix("http://")
        cleanedPattern = String(cleanedPattern.split(separator: "?")[0])
        if cleanedPattern == wildcard {
            return true
        } else if var host = url.host {
            if let port = url.port {
                host += ":\(port)"
            }
            
            let fullPath = host + url.path
            for (hostChar, patternChar) in zip(fullPath, cleanedPattern) {
                if String(patternChar) == wildcard {
                    return true
                } else if hostChar == patternChar {
                    continue
                }
                
                print(hostChar, patternChar)
                return false
            }
            
            return fullPath.count == pattern.count
        }
        
        return false
    }
}
