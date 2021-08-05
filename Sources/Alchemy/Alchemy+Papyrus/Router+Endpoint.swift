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
    
    public func decodeBody<T>(encoding: BodyEncoding = .json) throws -> T where T: Decodable {
        let body = try self.body.unwrap(or: PapyrusValidationError("Expecting a request body."))
        do {
            return try body.decodeJSON(as: T.self)
        } catch let DecodingError.keyNotFound(key, _) {
            throw PapyrusValidationError("Missing field `\(key.stringValue)` from request body.")
        } catch let DecodingError.typeMismatch(type, context) {
            let key = context.codingPath.last?.stringValue ?? "unknown"
            throw PapyrusValidationError("Request body field `\(key)` should be a `\(type)`.")
        } catch {
            throw PapyrusValidationError("Invalid request body.")
        }
    }
}

extension Endpoint {
    /// Converts the Papyrus HTTP verb type to it's NIO equivalent.
    fileprivate var nioMethod: HTTPMethod {
        HTTPMethod(rawValue: method)
    }
}
