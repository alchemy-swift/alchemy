import Foundation
import Papyrus
import NIO

public extension Router {
    /// Register an Endpoint.
    func register<Req, Res>(
        _ endpoint: Endpoint<Req, Res>,
        use closure: @escaping (HTTPRequest, Req) throws -> EventLoopFuture<Res>
    ) where Req: Decodable, Res: HTTPResponseEncodable {
        self.on(endpoint.method.nio, at: endpoint.path) {
            try closure($0, try Req(from: $0))
        }
    }
    
    /// Register an Endpoint with Empty request type.
    func register<Res>(
        _ endpoint: Endpoint<Empty, Res>,
        use closure: @escaping (HTTPRequest) throws -> EventLoopFuture<Res>
    ) where Res: HTTPResponseEncodable {
        self.on(endpoint.method.nio, at: endpoint.path, do: closure)
    }
    
    /// Register an Endpoint with a `Void` response type.
    func register<Req>(
        _ endpoint: Endpoint<Req, Empty>,
        use closure: @escaping (HTTPRequest, Req) throws -> EventLoopFuture<Void>
    ) where Req: Decodable {
        self.on(endpoint.method.nio, at: endpoint.path) {
            try closure($0, try Req(from: $0))
                .map(Empty.init)
        }
    }
}

extension HTTPRequest: DecodableRequest {
    public func getHeader(for key: String) throws -> String {
        try self.headers.first(name: key)
            .unwrap(or: PapyrusError("Expected `\(key)` in the request headers."))
    }
    
    public func getQuery(for key: String) throws -> String {
        try (self.queryItems
            .filter ({ $0.name == key })
            .first?
            .value)
            .unwrap(or: PapyrusError("Expected `\(key)` in the request query"))
    }
    
    public func getPathComponent(for key: String) throws -> String {
        try self.pathParameters.first(where: { $0.parameter == key })
            .unwrap(or: PapyrusError("Expected `\(key)` in the request path components."))
            .stringValue
    }
    
    public func getBody<T>() throws -> T where T : Decodable {
        do {
            return try self.body
                .unwrap(or: PapyrusError("There was no body in this request."))
                .decodeJSON(as: T.self)
        } catch {
            throw PapyrusError("Encountered an error decoding the body to type `\(T.self)`: \(error)")
        }
    }
}

extension EndpointMethod {
    fileprivate var nio: HTTPMethod {
        HTTPMethod(rawValue: self.rawValue)
    }
}
