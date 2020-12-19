import NIO

/// A `Middleware` is used to intercept incoming `HTTPRequest`s, do something, then pass that
/// request along to other `Middleware` or router handlers. Their "do something" can be synchronous
/// or asynchronous, and can also modify the `HTTPRequest`.
///
/// Usage:
/// ```
/// // Example synchronous middleware
/// struct SyncMiddleware: Middleware {
///     func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
///         ... // Do something with `request`.
///         // Then return a new `EventLoopFuture` with the `request`.
///         return .new(value: request)
///     }
/// }
///
/// // Example asynchronous middleware
/// struct AsyncMiddleware: Middleware {
///     func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
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
    /// Intercept a requst, returning a future with a request when whatever this middleware needs to
    /// do is finished.
    ///
    /// - Parameter request: the incoming request to intercept, then pass along the middleware /
    ///                      handler chain.
    func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest>
}
