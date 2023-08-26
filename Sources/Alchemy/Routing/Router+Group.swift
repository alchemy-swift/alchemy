extension Router {
    /// Creates a route group with the given prefix and middlewares. The prefix
    /// and middlewares will only be applied to routes defined on this
    /// specific group.
    public func group(_ pathPrefix: String? = nil, middlewares: [Middleware] = []) -> Router {
        appendGroup(prefixes: pathPrefix.map { [$0] } ?? [], middlewares: middlewares)
    }

    /// Groups a set of endpoints by a path prefix.
    /// All endpoints added in the `configure` closure will
    /// be prefixed, but none in the handler chain that continues
    /// after the `.grouped`.
    ///
    /// - Parameters:
    ///   - pathPrefix: The path prefix for all routes
    ///     defined in the `configure` closure.
    ///   - configure: A closure for adding routes that will be
    ///     prefixed by the given path prefix.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func grouping(_ pathPrefix: String? = nil, middlewares: [Middleware] = [], configure: (Router) -> Void) -> Self {
        configure(group(pathPrefix, middlewares: middlewares))
        return self
    }

    /// Groups a set of endpoints by a middleware. This middleware
    /// will handle all endpoints added in the `configure`
    /// closure, but none in the handler chain that
    /// continues after the `.group`.
    ///
    /// - Parameters:
    ///   - middleware: The middleware closure which will handle
    ///   all requests to this application.
    ///   - configure: A closure for adding endpoints that will be
    ///     intercepted by the given `Middleware`.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func grouping(_ pathPrefix: String? = nil, middleware: @escaping Middleware.Handler, configure: (Router) -> Void) -> Self {
        configure(group(middlewares: [AnonymousMiddleware(handler: middleware)]))
        return self
    }
}
