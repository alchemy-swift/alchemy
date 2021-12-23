import Foundation
import NIOHTTP1

public protocol RequestBuilder: ContentBuilder {
    associatedtype Res
    
    var urlComponents: URLComponents { get set }
    var method: HTTPMethod { get set }
    
    func execute() async throws -> Res
}

extension RequestBuilder {
    
    // MARK: Queries
    
    public func withQuery(_ name: String, value: String?) -> Self {
        with { request in
            let newItem = URLQueryItem(name: name, value: value)
            if let existing = request.urlComponents.queryItems {
                request.urlComponents.queryItems = existing + [newItem]
            } else {
                request.urlComponents.queryItems = [newItem]
            }
        }
    }
    
    public func withQueries(_ dict: [String: String]) -> Self {
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
    
    public func withMethod(_ method: HTTPMethod) -> Self {
        with { $0.method = method }
    }
    
    // MARK: Execution
    
    public func execute() async throws -> Res {
        try await execute()
    }
    
    public func request(_ method: HTTPMethod, uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(method).execute()
    }
    
    public func get(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.GET).execute()
    }
    
    public func post(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.POST).execute()
    }
    
    public func put(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.PUT).execute()
    }
    
    public func patch(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.PATCH).execute()
    }
    
    public func delete(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.DELETE).execute()
    }
    
    public func options(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.OPTIONS).execute()
    }
    
    public func head(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.HEAD).execute()
    }
}
