import NIO

/// A `Middleware` is used to intercept either incoming `Request`s or
/// outgoing `Response`s. Using futures, they can do something
/// with those, either synchronously or asynchronously.
///
/// Usage:
/// ```swift
/// // Example synchronous middleware
/// struct SyncMiddleware: Middleware {
///     func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response>
///         ... // Do something with `request`.
///         // Then continue the chain. Could hook into this future to
///         // do something with the `Response`.
///         return next(request)
///     }
/// }
///
/// // Example asynchronous middleware
/// struct AsyncMiddleware: Middleware {
///     func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response>
///         // Run some async operation
///         Database.default
///             .runRawQuery(...)
///             .flatMap { someData in
///                 // Set some data on the request for access in
///                 // subsequent Middleware or request handlers.
///                 // See `HTTPRequst.set` for more detail.
///                 request.set(someData)
///                 return next(request)
///             }
///     }
/// }
/// ```
public protocol Middleware {
    /// Passes a request to the next piece of the handler chain. It is
    /// a closure that expects a request and returns a future
    /// containing a response.
    typealias Next = (Request) -> EventLoopFuture<Response>
    
    /// Intercept a requst, returning a future with a Response
    /// representing the result of the subsequent handlers.
    ///
    /// Be sure to call next when returning, unless you don't want the
    /// request to be handled.
    ///
    /// - Parameter request: The incoming request to intercept, then
    ///   pass along the handler chain.
    /// - Throws: Any error encountered when intercepting the request.
    func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response>
}
