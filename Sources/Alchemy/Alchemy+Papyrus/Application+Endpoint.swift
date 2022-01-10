import Foundation
import Papyrus
import NIO
import NIOHTTP1

extension RawResponse: ResponseConvertible {
    public func response() async throws -> Response {
        var headers: HTTPHeaders = [:]
        headers.add(contentsOf: self.headers.map { $0 })
        return Response(status: .ok, headers: headers, body: body.map { .data($0) })
    }
}

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
    func on<Req, Res>(_ endpoint: Endpoint<Req, Res>, options: Router.RouteOptions = [], use handler: @escaping (Request, Req) async throws -> Res) -> Self where Res: Codable {
        on(endpoint.nioMethod, at: endpoint.path, options: options) { request -> RawResponse in
            let input = try endpoint.decodeRequest(method: request.method.rawValue, path: request.path, headers: request.headerDict, parameters: request.parameterDict, query: request.urlComponents.query ?? "", body: request.body?.data())
            let output = try await handler(request, input)
            return try endpoint.rawResponse(with: output)
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
    func on<Res>(_ endpoint: Endpoint<Empty, Res>, options: Router.RouteOptions = [], use handler: @escaping (Request) async throws -> Res) -> Self {
        on(endpoint.nioMethod, at: endpoint.path, options: options) { request -> RawResponse in
            let output = try await handler(request)
            return try endpoint.rawResponse(with: output)
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
    func on<Req>(_ endpoint: Endpoint<Req, Empty>, options: Router.RouteOptions = [], use handler: @escaping (Request, Req) async throws -> Void) -> Self {
        on(endpoint.nioMethod, at: endpoint.path, options: options) { request -> Response in
            let input = try endpoint.decodeRequest(method: request.method.rawValue, path: request.path, headers: request.headerDict, parameters: request.parameterDict, query: request.urlComponents.query ?? "", body: request.body?.data())
            try await handler(request, input)
            return Response()
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
    func on(_ endpoint: Endpoint<Empty, Empty>, options: Router.RouteOptions = [], use handler: @escaping (Request) async throws -> Void) -> Self {
        on(endpoint.nioMethod, at: endpoint.path, options: options) { request -> Response in
            try await handler(request)
            return Response()
        }
    }
}

extension Request {
    fileprivate var parameterDict: [String: String] {
        var dict: [String: String] = [:]
        for param in parameters { dict[param.key] = param.value }
        return dict
    }
    
    fileprivate var headerDict: [String: String] {
        var dict: [String: String] = [:]
        for header in headers { dict[header.name] = header.value }
        return dict
    }
}

extension Endpoint {
    /// Converts the Papyrus HTTP verb type to it's NIO equivalent.
    fileprivate var nioMethod: HTTPMethod {
        HTTPMethod(rawValue: method)
    }
}
