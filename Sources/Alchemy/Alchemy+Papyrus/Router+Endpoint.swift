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
    ///     match this endpoint's path. This handler expects a
    ///     future containing an instance of the endpoint's
    ///     response type.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Req, Res>(
        _ endpoint: Endpoint<Req, Res>,
        use handler: @escaping (Request, Req) throws -> EventLoopFuture<Res>
    ) -> Self where Res: Codable {
        self.on(endpoint.nioMethod, at: endpoint.path) {
            return try handler($0, try Req(from: $0))
                .flatMapThrowing { Response(status: .ok, body: try HTTPBody(json: $0, encoder: endpoint.jsonEncoder)) }
        }
    }
    
    /// Registers a `Papyrus.Endpoint` that has an `Empty` request
    /// type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to register on this application.
    ///   - handler: The handler for handling incoming requests that
    ///     match this endpoint's path. This handler expects a future
    ///     containing an instance of the endpoint's response type.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Res>(
        _ endpoint: Endpoint<Empty, Res>,
        use handler: @escaping (Request) throws -> EventLoopFuture<Res>
    ) -> Self {
        self.on(endpoint.nioMethod, at: endpoint.path) {
            return try handler($0)
                .flatMapThrowing { Response(status: .ok, body: try HTTPBody(json: $0, encoder: endpoint.jsonEncoder)) }
        }
    }
}

extension EventLoopFuture {
    /// Changes the `Value` of this future to `Empty`. Used for
    /// interaction with Papyrus APIs.
    ///
    /// - Returns: An "empty" `EventLoopFuture`.
    public func emptied() -> EventLoopFuture<Empty> {
        self.map { _ in Empty.value }
    }
}

// Provide a custom response for when `PapyrusValidationError`s are
// thrown.
extension PapyrusValidationError: ResponseConvertible {
    public func convert() throws -> EventLoopFuture<Response> {
        let body = try HTTPBody(json: ["validation_error": self.message])
        return .new(Response(status: .badRequest, body: body))
    }
}

extension Request: DecodableRequest {
    public func header(for key: String) -> String? {
        self.headers.first(name: key)
    }
    
    public func query(for key: String) -> String? {
        self.queryItems
            .filter ({ $0.name == key })
            .first?
            .value
    }
    
    public func pathComponent(for key: String) -> String? {
        self.pathParameters.first(where: { $0.parameter == key })?
            .stringValue
    }
    
    /// Returns the first `PathParameter` for the given key,
    /// converting the value to the given type. Throws if the value is
    /// not there or not convertible to the given type.
    ///
    /// Use this to fetch any parameters from the path.
    /// ```swift
    /// app.post("/users/:user_id") { request in
    ///     let userID: String = try request.pathComponent("user_id")
    ///     ...
    /// }
    /// ```
    public func parameter<T: StringInitializable>(_ key: String) throws -> T {
        guard let stringValue = pathParameters.first(where: { $0.parameter == "key" })?.stringValue else {
            throw PapyrusValidationError("Missing parameter `\(key)` from path.")
        }
        
        return try T(stringValue)
            .unwrap(or: PapyrusValidationError("Path parameter `\(key)` was not convertible to a `\(name(of: T.self))`"))
    }
    
    public func decodeBody<T: Decodable>(as: T.Type = T.self, with decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let body = try body.unwrap(or: PapyrusValidationError("Expecting a request body."))
        do {
            return try body.decodeJSON(as: T.self, with: decoder)
        } catch let DecodingError.keyNotFound(key, _) {
            throw PapyrusValidationError("Missing field `\(key.stringValue)` from request body.")
        } catch let DecodingError.typeMismatch(type, context) {
            let key = context.codingPath.last?.stringValue ?? "unknown"
            throw PapyrusValidationError("Request body field `\(key)` should be a `\(type)`.")
        } catch {
            throw PapyrusValidationError("Invalid request body.")
        }
    }
    
    public func decodeBody<T>(encoding: BodyEncoding = .json) throws -> T where T: Decodable {
        return try decodeBody(as: T.self)
    }
}

extension Endpoint {
    /// Converts the Papyrus HTTP verb type to it's NIO equivalent.
    fileprivate var nioMethod: HTTPMethod {
        HTTPMethod(rawValue: method)
    }
}
