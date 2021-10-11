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
    
    // MARK: Content
    
    public func withHeaders(_ dict: [String: String]) -> Builder {
        var toReturn = builder
        for (k, v) in dict {
            toReturn = withHeader(k, value: v)
        }
        
        return toReturn
    }
    
    public func withQueries(_ dict: [String: String]) -> Builder {
        var toReturn = builder
        for (k, v) in dict {
            toReturn = withQuery(k, value: v)
        }
        
        return toReturn
    }
    
    public func withBasicAuth(username: String, password: String) -> Builder {
        let auth = Data("\(username):\(password)".utf8).base64EncodedString()
        return withHeader("Authorization", value: "Basic \(auth)")
    }
    
    public func withBearerAuth(_ token: String) -> Builder {
        return withHeader("Authorization", value: "Bearer \(token)")
    }
    
    public func withBody(_ dict: [String: Any?]) -> Builder {
        self
            .withBody { ByteBuffer(data: try JSONSerialization.data(withJSONObject: dict)) }
            .withHeader("Content-Type", value: "application/json")
    }
    
    public func withBody<T: Encodable>(_ body: T) -> Builder {
        self
            .withBody { ByteBuffer(data: try JSONEncoder().encode(body)) }
            .withHeader("Content-Type", value: "application/json")
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
    
    public func head(_ path: String) async throws -> Res {
        try await request(.HEAD, path)
    }
}
