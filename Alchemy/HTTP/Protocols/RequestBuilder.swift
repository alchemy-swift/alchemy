public protocol RequestBuilder: HTTPBuilder {
    associatedtype Res
    
    var urlComponents: URLComponents { get set }
    var method: HTTPRequest.Method { get set }
    
    func execute() async throws -> Res
}

extension RequestBuilder {
    
    // MARK: Queries
    
    public func withQuery(_ name: String, value: CustomStringConvertible?) -> Self {
        with { request in
            let newItem = URLQueryItem(name: name, value: value?.description)
            if let existing = request.urlComponents.queryItems {
                request.urlComponents.queryItems = existing + [newItem]
            } else {
                request.urlComponents.queryItems = [newItem]
            }
        }
    }
    
    public func withQueries(_ dict: [String: CustomStringConvertible]) -> Self {
        dict.reduce(self) { $0.withQuery($1.key, value: $1.value) }
    }
    
    // MARK: Methods & URL
    
    public func withBaseUrl(_ url: String) -> Self {
        with {
            var newComponents = URLComponents(string: url)
            if let oldQueryItems = $0.urlComponents.queryItems {
                let newQueryItems = newComponents?.queryItems ?? []
                newComponents?.queryItems = newQueryItems + oldQueryItems
            }
            
            $0.urlComponents = newComponents ?? URLComponents()
        }
    }
    
    public func withMethod(_ method: HTTPRequest.Method) -> Self {
        with { $0.method = method }
    }
    
    // MARK: Execution
    
    public func execute() async throws -> Res {
        try await execute()
    }
    
    public func request(_ method: HTTPRequest.Method, uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(method).execute()
    }
    
    public func get(_ uri: String) async throws -> Res {
        try await request(.get, uri: uri)
    }
    
    public func post(_ uri: String) async throws -> Res {
        try await request(.post, uri: uri)
    }
    
    public func put(_ uri: String) async throws -> Res {
        try await request(.put, uri: uri)
    }
    
    public func patch(_ uri: String) async throws -> Res {
        try await request(.patch, uri: uri)
    }
    
    public func delete(_ uri: String) async throws -> Res {
        try await request(.delete, uri: uri)
    }
    
    public func options(_ uri: String) async throws -> Res {
        try await request(.options, uri: uri)
    }
    
    public func head(_ uri: String) async throws -> Res {
        try await request(.head, uri: uri)
    }
}
