protocol RequestBuilder {
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
    
    func withHeader(_ header: String, value: String) -> Builder {
        builder.withHeader(header, value: value)
    }
    
    func withQuery(_ query: String, value: String) -> Builder {
        builder.withQuery(query, value: value)
    }
    
    func withBody(_ createBody: @escaping () throws -> ByteBuffer?) -> Builder {
        builder.withBody(createBody)
    }
    
    func request(_ method: HTTPMethod, _ path: String) async throws -> Res {
        try await builder.request(method, path)
    }
    
    // MARK: Content
    
    func withHeaders(_ dict: [String: String]) -> Builder {
        var toReturn = builder
        for (k, v) in dict {
            toReturn = withHeader(k, value: v)
        }
        
        return toReturn
    }
    
    func withQueries(_ dict: [String: String]) -> Builder {
        var toReturn = builder
        for (k, v) in dict {
            toReturn = withQuery(k, value: v)
        }
        
        return toReturn
    }
    
    func withBasicAuth(username: String, password: String) -> Builder {
        let auth = Data("\(username):\(password)".utf8).base64EncodedString()
        return withHeader("Authorization", value: "Basic \(auth)")
    }
    
    func withBearerAuth(_ token: String) -> Builder {
        return withHeader("Authorization", value: "Bearer \(token)")
    }
    
    func withBody(_ dict: [String: Any?]) -> Builder {
        self
            .withBody { ByteBuffer(data: try JSONSerialization.data(withJSONObject: dict)) }
            .withHeader("Content-Type", value: "application/json")
    }
    
    func withBody<T: Encodable>(_ body: T) -> Builder {
        self
            .withBody { ByteBuffer(data: try JSONEncoder().encode(body)) }
            .withHeader("Content-Type", value: "application/json")
    }
    
    // MARK: Methods
    
    func get(_ path: String) async throws -> Res {
        try await request(.GET, path)
    }
    
    func post(_ path: String) async throws -> Res {
        try await request(.POST, path)
    }
    
    func put(_ path: String) async throws -> Res {
        try await request(.PUT, path)
    }
    
    func patch(_ path: String) async throws -> Res {
        try await request(.PATCH, path)
    }
    
    func head(_ path: String) async throws -> Res {
        try await request(.HEAD, path)
    }
}
