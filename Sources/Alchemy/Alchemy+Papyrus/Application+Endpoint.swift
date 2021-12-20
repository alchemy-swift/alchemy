import Foundation
import Papyrus
import NIO

public extension Application {
    /// Registers a `Papyrus.Endpoint`. When an incoming request
    /// matches the path of the `Endpoint`, the `Endpoint.Request`
    /// will automatically be decoded from the incoming
    /// `HTTPRequest` for use in the provided handler.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to register on this router.
    ///   - handler: The handler for handling incoming requests that
    ///     match this endpoint's path. This handler returns an
    ///     instance of the endpoint's response type.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Req, Res>(_ endpoint: Endpoint<Req, Res>, use handler: @escaping (Request, Req) async throws -> Res) -> Self where Res: Codable {
        on(endpoint.nioMethod, at: endpoint.path) { request -> Response in
            let result = try await handler(request, try Req(from: request.collect()))
            return try Response(status: .ok)
                .withValue(result, encoder: endpoint.jsonEncoder)
        }
    }
    
    /// Registers a `Papyrus.Endpoint` that has an `Empty` request
    /// type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to register on this application.
    ///   - handler: The handler for handling incoming requests that
    ///     match this endpoint's path. This handler returns an
    ///     instance of the endpoint's response type.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Res>(_ endpoint: Endpoint<Empty, Res>, use handler: @escaping (Request) async throws -> Res) -> Self {
        on(endpoint.nioMethod, at: endpoint.path) { request -> Response in
            let result = try await handler(request)
            return try Response(status: .ok)
                .withValue(result, encoder: endpoint.jsonEncoder)
        }
    }
    
    /// Registers a `Papyrus.Endpoint` that has an `Empty` response
    /// type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to register on this application.
    ///   - handler: The handler for handling incoming requests that
    ///     match this endpoint's path. This handler returns Void.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Req>(_ endpoint: Endpoint<Req, Empty>, use handler: @escaping (Request, Req) async throws -> Void) -> Self {
        on(endpoint.nioMethod, at: endpoint.path) { request -> Response in
            try await handler(request, Req(from: request.collect()))
            return Response(status: .ok, body: nil)
        }
    }
    
    /// Registers a `Papyrus.Endpoint` that has an `Empty` request and
    /// response type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to register on this application.
    ///   - handler: The handler for handling incoming requests that
    ///     match this endpoint's path. This handler returns Void.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on(_ endpoint: Endpoint<Empty, Empty>, use handler: @escaping (Request) async throws -> Void) -> Self {
        on(endpoint.nioMethod, at: endpoint.path) { request -> Response in
            try await handler(request)
            return Response(status: .ok, body: nil)
        }
    }
}

extension Endpoint {
    /// Converts the Papyrus HTTP verb type to it's NIO equivalent.
    fileprivate var nioMethod: HTTPMethod {
        HTTPMethod(rawValue: method)
    }
}
