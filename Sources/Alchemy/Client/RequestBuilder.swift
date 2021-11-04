import Foundation

public protocol RequestBuilder {
    associatedtype Res
    associatedtype Builder: RequestBuilder where Builder.Builder == Builder, Builder.Res == Res
    
    var builder: Builder { get }
    
    func withHeader(_ header: String, value: String) -> Builder
    func withQuery(_ query: String, value: String) -> Builder
    func withBody(_ createBody: @escaping () throws -> ByteBuffer?) -> Builder
    func request(_ method: HTTPMethod, _ path: String) async throws -> Res
}

extension RequestBuilder {
    // MARK: Default Implementations
    
    public func withHeader(_ header: String, value: String) -> Builder {
        builder.withHeader(header, value: value)
    }
    
    public func withQuery(_ query: String, value: String) -> Builder {
        builder.withQuery(query, value: value)
    }
    
    public func withBody(_ createBody: @escaping () throws -> ByteBuffer?) -> Builder {
        builder.withBody(createBody)
    }
    
    public func request(_ method: HTTPMethod, _ path: String) async throws -> Res {
        try await builder.request(method, path)
    }
    
    // MARK: Queries
    
    public func withQueries(_ dict: [String: String]) -> Builder {
        var toReturn = builder
        for (k, v) in dict {
            toReturn = toReturn.withQuery(k, value: v)
        }
        
        return toReturn
    }
    
    // MARK: - Headers
    
    public func withHeaders(_ dict: [String: String]) -> Builder {
        var toReturn = builder
        for (k, v) in dict {
            toReturn = toReturn.withHeader(k, value: v)
        }
        
        return toReturn
    }
    
    public func withBasicAuth(username: String, password: String) -> Builder {
        let auth = Data("\(username):\(password)".utf8).base64EncodedString()
        return withHeader("Authorization", value: "Basic \(auth)")
    }
    
    public func withBearerAuth(_ token: String) -> Builder {
        withHeader("Authorization", value: "Bearer \(token)")
    }
    
    public func withContentType(_ contentType: ContentType) -> Builder {
        withHeader("Content-Type", value: contentType.value)
    }
    
    // MARK: - Body
    
    public func withBody(_ data: Data?) -> Builder {
        guard let data = data else {
            return builder
        }

        return withBody { ByteBuffer(data: data) }
    }
    
    public func withJSON(_ dict: [String: Any?]) -> Builder {
        self
            .withBody { ByteBuffer(data: try JSONSerialization.data(withJSONObject: dict)) }
            .withContentType(.json)
    }
    
    public func withJSON<T: Encodable>(_ body: T, encoder: JSONEncoder = JSONEncoder()) -> Builder {
        withBody { ByteBuffer(data: try encoder.encode(body)) }
            .withContentType(.json)
    }
    
    // MARK: Methods
    
    public func get(_ path: String) async throws -> Res {
        try await request(.GET, path)
    }
    
    public func post(_ path: String) async throws -> Res {
        try await request(.POST, path)
    }
    
    public func put(_ path: String) async throws -> Res {
        try await request(.PUT, path)
    }
    
    public func patch(_ path: String) async throws -> Res {
        try await request(.PATCH, path)
    }
    
    public func delete(_ path: String) async throws -> Res {
        try await request(.DELETE, path)
    }
    
    public func head(_ path: String) async throws -> Res {
        try await request(.HEAD, path)
    }
    
    public func options(_ path: String) async throws -> Res {
        try await request(.OPTIONS, path)
    }
}
