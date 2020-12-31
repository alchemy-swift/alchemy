import Foundation
import NIO
import NIOHTTP1

/// A simplified Request type as you'll come across in many web frameworks
public final class Request {
    /// The default JSONDecoder with which to decode HTTP request bodies.
    public static var defaultJSONDecoder = JSONDecoder()
    
    /// The head contains all request "metadata" like the URI and request method
    ///
    /// The headers are also found in the head, and they are often used to
    /// describe the body as well.
    public let head: HTTPRequestHead
    
    /// The url components of this request.
    public let components: URLComponents?
    
    /// The any parameters inside the path.
    public var pathParameters: [PathParameter] = []
    
    /// The bodyBuffer is internal because the HTTPBody API is exposed for
    /// simpler access.
    var bodyBuffer: ByteBuffer?
    
    /// Any information set by a middleware.
    var middlewareData: [ObjectIdentifier: Any] = [:]
    
    /// This initializer is necessary because the `bodyBuffer` is a private property
    init(head: HTTPRequestHead, bodyBuffer: ByteBuffer?) {
        self.head = head
        self.bodyBuffer = bodyBuffer
        self.components = URLComponents(string: head.uri)
    }
}

extension Request {
    /// The HTTPMethod of the request.
    public var method: HTTPMethod {
        self.head.method
    }
    
    /// The path of the request. Does not include the query string.
    public var path: String {
        self.components?.path ?? ""
    }
    
    /// Any headers associated with the request.
    public var headers: HTTPHeaders {
        self.head.headers
    }
    
    /// Any query items parsed from the URL. These are not percent encoded.
    public var queryItems: [URLQueryItem] {
        self.components?.queryItems ?? []
    }
    
    /// Returns the first `PathParameter` for the given key, if there is one.
    ///
    /// Use this to fetch any parameters from the path.
    /// ```
    /// router.on(.POST, at: "/users/:user_id") { request in
    ///     let theUserID = request.pathParameter(named: "user_id")?.stringValue
    ///     ...
    /// }
    /// ```
    public func pathParameter(named key: String) -> PathParameter? {
        self.pathParameters.first(where: { $0.parameter == "key" })
    }
    
    /// The body is a wrapper used to provide simple access to any body data,
    /// such as JSON.
    public var body: HTTPBody? {
        guard let bodyBuffer = bodyBuffer else {
            return nil
        }
        
        return HTTPBody(buffer: bodyBuffer)
    }
    
    /// Sets a value associated with this request. Useful for setting objects
    /// with middleware.
    ///
    /// - Parameter value: the value
    /// - Returns: self, with the new value set internally for access with
    ///            `self.get(Value.self)`.
    ///
    /// ```
    /// struct ExampleMiddleware: Middleware {
    ///     func intercept(_ request: Request) -> EventLoopFuture<Request> {
    ///         let someData: SomeData = ...
    ///         request.set(someData)
    ///         return .new(value: request)
    ///     }
    /// }
    ///
    /// router
    ///     .middleware(ExampleMiddleware())
    ///     .on(.GET, at: "/example") { request in
    ///         let theData = try request.get(SomeData.self)
    ///     }
    ///
    /// ```
    public func set<T>(_ value: T) -> Self {
        self.middlewareData[identifier(of: T.self)] = value
        return self
    }
    
    /// Gets a value associated with this request, throws if there is not a
    /// value of type `T` already set.
    ///
    /// - Parameter type: the type of the associated value to get from the
    ///                   request.
    /// - Throws: a `AssociatedValueError` if there isn't a value of type `T`
    ///           found associated with the request.
    /// - Returns: the value of type `T` from the request.
    public func get<T>(_ type: T.Type = T.self) throws -> T {
        try self.middlewareData[identifier(of: T.self)]
            .unwrap(
                as: type,
                or: AssociatedValueError(
                    "Couldn't find type `\(name(of: type))` on this request"
                )
            )
    }
}

/// Error thrown when the user tries to `.get` an assocaited value from an
/// `Request` but one isn't set.
struct AssociatedValueError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
