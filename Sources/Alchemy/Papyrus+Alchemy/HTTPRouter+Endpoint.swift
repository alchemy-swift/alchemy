import Foundation
import Papyrus
import NIO

extension Empty: HTTPResponseEncodable {}

public extension Router {
    /// Register an Endpoint.
    func register<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                            use closure: @escaping (HTTPRequest, Req) throws -> EventLoopFuture<Res>)
        where Req: Decodable, Res: HTTPResponseEncodable
    {
        self.registerRequest(endpoint) {
            try closure($0, try Req(from: $0))
        }
    }
    
    /// Register an Endpoint with Empty request type.
    func register<Res>(_ endpoint: Endpoint<Empty, Res>,
                       use closure: @escaping (HTTPRequest) throws -> EventLoopFuture<Res>) where Res: HTTPResponseEncodable
    {
        self.registerRequest(endpoint, closure)
    }
    
    /// Register an Endpoint with a `Void` response type.
    func register<Req>(_ endpoint: Endpoint<Req, Empty>,
                       use closure: @escaping (HTTPRequest, Req) throws -> EventLoopFuture<Void>) where Req: Decodable
    {
        self.registerRequest(endpoint) {
            try closure($0, try Req(from: $0))
                .map { Empty() }
        }
    }
    
    private func registerRequest<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                                           _ closure: @escaping (HTTPRequest) throws -> EventLoopFuture<Res>)
        where Res: HTTPResponseEncodable
    {
        self.on(endpoint.method.nio, at: endpoint.basePath, do: closure)
    }
}

extension RequestAllowed {
    init(from request: HTTPRequest) throws {
        if Self.self is BodyCodable.Type {
            guard let body = request.bodyBuffer else {
                throw PapyrusError("Attempting to decode a `RequestBodyCodable` from a request with no body!")
            }
            
            self = try JSONDecoder().decode(Self.self, from: body)
        } else {
            try self.init(from: HTTPRequestDecoder(request: request, keyMappingStrategy: .convertToSnakeCase))
        }
    }
}
