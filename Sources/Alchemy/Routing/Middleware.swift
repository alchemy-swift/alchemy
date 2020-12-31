import NIO

/// A `Middleware` is used to intercept incoming `Request`s, do something, then pass that
/// request along to other `Middleware` or router handlers. Their "do something" can be synchronous
/// or asynchronous, and can also modify the `Request`.
///
/// Usage:
/// ```
/// // Example synchronous middleware
/// struct SyncMiddleware: Middleware {
///     func intercept(_ request: Request) -> EventLoopFuture<Request> {
///         ... // Do something with `request`.
///         // Then return a new `EventLoopFuture` with the `request`.
///         return .new(value: request)
///     }
/// }
///
/// // Example asynchronous middleware
/// struct AsyncMiddleware: Middleware {
///     func intercept(_ request: Request) -> EventLoopFuture<Request> {
///         // Run some async operation
///         DB.default
///             .runRawQuery(...)
///             .map { someData in
///                 // Set some data on the request for access in other Middleware or router
///                 // handlers. See `HTTPRequst.set` for more detail.
///                 return request.set(someData)
///             }
///     }
/// }
/// ```
///
public protocol Middleware {
    /// The expected closure tyoe of a `Middleware.intercept`'s next parameter. It is a closure that
    /// expects a request and returns a future containing a response.
    typealias MiddlewareNext = (Request) -> EventLoopFuture<Response>
    
    /// Intercept a requst, returning a future with a request when whatever this middleware needs to
    /// do is finished.
    ///
    /// - Parameter request: the incoming request to intercept, then pass along the middleware /
    ///                      handler chain.
    func intercept(_ request: Request, next: @escaping MiddlewareNext) -> EventLoopFuture<Response>
}
