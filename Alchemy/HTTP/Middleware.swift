/// A `Middleware` is used to handle either incoming `Request`s or outgoing
/// `Response`s. The can handle either synchronously or asynchronously.
///
/// Usage:
/// ```swift
/// // Log all requests and responses to the server
/// struct RequestLoggingMiddleware: Middleware {
///     func handle(_ request: Request, next: Next) async throws -> Response {
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
/// // Find and set a user on a Request if the request path has a `user_id` parameter
/// struct FindUserMiddleware: Middleware {
///     func handle(_ request: Request, next: Next) async throws -> Response {
///         let userId = request.parameter(for: "user_id")
///         let user = try await User.find(userId)
///
///         // Set some data on the request for access in subsequent Middleware
///         // or request handlers. See `HTTPRequst.set` for more detail.
///         return try await next(request.set(user))
///     }
/// }
/// ```
public protocol Middleware {
    /// The type signature of a Middleware handle function.
    typealias Handler = (Request, Next) async throws -> Response

    /// Passes a request to the next piece of the handler chain. Next is a
    /// closure that expects a request and returns a response.
    typealias Next = (Request) async throws -> Response
    
    /// Intercept a requst, returning a Response representing from the
    /// subsequent handlers.
    ///
    /// Be sure to call `next` when returning, unless you don't want the request
    /// to be handled.
    ///
    /// - Parameter request: The incoming request to handle, then
    ///   pass along the handler chain.
    func handle(_ request: Request, next: Next) async throws -> Response
}

/// An array of `Middleware` can be used like a single `Middleware`. The request
/// will be consecutively passed through each middleware.
extension [Middleware]: Middleware {
    public func handle(_ request: Request, next: Next) async throws -> Response {
        try await send(request: request, through: self, finally: next)
    }

    private func send(request: Request, through middlewares: [Middleware], finally: Next) async throws -> Response {
        guard let first = middlewares.first else {
            return try await finally(request)
        }

        return try await first.handle(request) {
            try await send(request: $0, through: Array(middlewares.dropFirst()), finally: finally)
        }
    }
}
