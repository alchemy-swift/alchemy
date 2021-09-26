import NIO

/// A `Middleware` is used to intercept either incoming `Request`s or
/// outgoing `Response`s. Using futures, they can do something
/// with those, either synchronously or asynchronously.
///
/// Usage:
/// ```swift
/// // Log all requests and responses to the server
/// struct RequestLoggingMiddleware: Middleware {
///     func intercept(_ request: Request, next: Next) async throws -> Response {
///         // log the request
///         Log.info("\(request.head.method.rawValue) \(request.path)")
///
///         // await and log the response
///         let response = try await next(request)
///         Log.info("\(response.status.code) \(request.head.method.rawValue) \(request.path)")
///         return response
///     }
/// }
///
/// // Find and set a user on a Request if the request path has a
/// // `user_id` parameter
/// struct FindUserMiddleware: Middleware {
///     func intercept(_ request: Request, next: Next) async throws -> Response {
///         let userId = request.pathComponent(for: "user_id")
///         let user = try await User.find(userId)
///         // Set some data on the request for access in subsequent
///         // Middleware or request handlers. See `HTTPRequst.set`
///         // for more detail.
///         return try await next(request.set(user))
///     }
/// }
/// ```
public protocol Middleware {
    /// Passes a request to the next piece of the handler chain. It is
    /// a closure that expects a request and returns a future
    /// containing a response.
    typealias Next = (Request) async throws -> Response
    
    /// Intercept a requst, returning a future with a Response
    /// representing the result of the subsequent handlers.
    ///
    /// Be sure to call next when returning, unless you don't want the
    /// request to be handled.
    ///
    /// - Parameter request: The incoming request to intercept, then
    ///   pass along the handler chain.
    /// - Throws: Any error encountered when intercepting the request.
    func intercept(_ request: Request, next: Next) async throws -> Response
}
