import Foundation
import NIO
import NIOHTTP1

/// A simplified Request type as you'll come across in many web
/// frameworks
public final class Request {
    /// The default JSONDecoder with which to decode HTTP request
    /// bodies.
    public static var defaultJSONDecoder = JSONDecoder()
    
    /// The head contains all request "metadata" like the URI and
    /// request method.
    ///
    /// The headers are also found in the head, and they are often
    /// used to describe the body as well.
    public let head: HTTPRequestHead
    
    /// Any parameters inside the path.
    public var parameters: [Parameter] = []
    
    /// The bodyBuffer is internal because the HTTPBody API is exposed
    /// for easier access.
    var bodyBuffer: ByteBuffer?
    
    /// Any information set by a middleware.
    var storage: [ObjectIdentifier: Any] = [:]
    
    /// This initializer is necessary because the `bodyBuffer` is a
    /// private property.
    init(head: HTTPRequestHead, bodyBuffer: ByteBuffer?) {
        self.head = head
        self.bodyBuffer = bodyBuffer
    }
}

extension Request {
    /// The HTTPMethod of the request.
    public var method: HTTPMethod {
        head.method
    }
    
    /// Any headers associated with the request.
    public var headers: HTTPHeaders {
        head.headers
    }
    
    /// The url components of this request.
    public var components: URLComponents? {
        URLComponents(string: head.uri)
    }
    
    /// The path of the request. Does not include the query string.
    public var path: String {
        URLComponents(string: head.uri)?.path ?? ""
    }
    
    /// Any query items parsed from the URL. These are not percent
    /// encoded.
    public var queryItems: [URLQueryItem] {
        URLComponents(string: head.uri)?.queryItems ?? []
    }
    
    /// Returns the first parameter for the given key, if there is one.
    ///
    /// Use this to fetch any parameters from the path.
    /// ```swift
    /// app.post("/users/:user_id") { request in
    ///     let userID = try request.parameter("user_id")?.int()
    ///     ...
    /// }
    /// ```
    public func parameter(_ key: String) -> Parameter? {
        parameters.first(where: { $0.key == key })
    }
    
    /// The body is a wrapper used to provide simple access to any
    /// body data, such as JSON.
    public var body: HTTPBody? {
        guard let bodyBuffer = bodyBuffer else {
            return nil
        }
        
        return HTTPBody(buffer: bodyBuffer)
    }
    
    /// A dictionary with the contents of this Request's body.
    /// - Throws: Any errors from decoding the body.
    /// - Returns: A [String: Any] with the contents of this Request's
    ///   body.
    public func decodeBodyDict() throws -> [String: Any]? {
        try body?.decodeJSONDictionary()
    }
    
    /// Decodes the request body to the given type using the given
    /// `JSONDecoder`.
    ///
    /// - Returns: The type, decoded as JSON from the request body.
    public func decodeBodyJSON<T: Decodable>(as type: T.Type = T.self, with decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let body = try body.unwrap(or: ValidationError("Expecting a request body."))
        do {
            return try body.decodeJSON(as: type, with: decoder)
        } catch let DecodingError.keyNotFound(key, _) {
            throw ValidationError("Missing field `\(key.stringValue)` from request body.")
        } catch let DecodingError.typeMismatch(type, context) {
            let key = context.codingPath.last?.stringValue ?? "unknown"
            throw ValidationError("Request body field `\(key)` should be a `\(type)`.")
        } catch {
            throw ValidationError("Invalid request body.")
        }
    }
}

extension Request {
    /// Sets a value associated with this request. Useful for setting
    /// objects with middleware.
    ///
    /// Usage:
    /// ```swift
    /// struct ExampleMiddleware: Middleware {
    ///     func intercept(_ request: Request, next: Next) async throws -> Response {
    ///         let someData: SomeData = ...
    ///         return try await next(request.set(someData))
    ///     }
    /// }
    ///
    /// app
    ///     .use(ExampleMiddleware())
    ///     .on(.GET, at: "/example") { request in
    ///         let theData = try request.get(SomeData.self)
    ///     }
    ///
    /// ```
    ///
    /// - Parameter value: The value to set.
    /// - Returns: `self`, with the new value set internally for
    ///   access with `self.get(Value.self)`.
    @discardableResult
    public func set<T>(_ value: T) -> Self {
        storage[ObjectIdentifier(T.self)] = value
        return self
    }
    
    /// Gets a value associated with this request, throws if there is
    /// not a value of type `T` already set.
    ///
    /// - Parameter type: The type of the associated value to get from
    ///   the request.
    /// - Throws: An `AssociatedValueError` if there isn't a value of
    ///   type `T` found associated with the request.
    /// - Returns: The value of type `T` from the request.
    public func get<T>(_ type: T.Type = T.self) throws -> T {
        let error = AssociatedValueError(message: "Couldn't find type `\(name(of: type))` on this request")
        return try storage[ObjectIdentifier(T.self)]
            .unwrap(as: type, or: error)
    }
}

/// Error thrown when the user tries to `.get` an assocaited value
/// from an `Request` but one isn't set.
struct AssociatedValueError: Error {
    /// What went wrong.
    let message: String
}

private extension Optional {
    /// Unwraps an optional as the provided type or throws the
    /// provided error.
    ///
    /// - Parameters:
    ///   - as: The type to unwrap to.
    ///   - error: The error to be thrown if `self` is unable to be
    ///            unwrapped as the provided type.
    /// - Throws: An error if unwrapping as the provided type fails.
    /// - Returns: `self` unwrapped and cast as the provided type.
    func unwrap<T>(as: T.Type = T.self, or error: Error) throws -> T {
        guard let wrapped = self as? T else {
            throw error
        }
        
        return wrapped
    }
}
