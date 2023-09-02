extension Router {
    /// Creates a route group with the given prefix and middlewares. The prefix
    /// and middlewares will only be applied to routes defined on this
    /// specific group.
    public func group(_ pathPrefix: String? = nil, middlewares: [Middleware] = []) -> Router {
        appendGroup(prefixes: pathPrefix.map { [$0] } ?? [], middlewares: middlewares)
    }

    /// Groups a set of endpoints by a path prefix. All endpoints added in the
    /// `configure` closure will be prefixed and run through the given
    /// middleware(s).
    ///
    /// - Parameters:
    ///   - pathPrefix: The path prefix for all routes defined in `configure`.
    ///   - middlewares: Middlewares to apply to the group.
    ///   - configure: A closure for adding routes that will be prefixed by the
    ///     given path prefix and have the given middlewares applied.
    @discardableResult
    public func grouping(_ pathPrefix: String? = nil, middlewares: [Middleware] = [], configure: (Router) -> Void) -> Self {
        configure(group(pathPrefix, middlewares: middlewares))
        return self
    }

    /// Groups a set of endpoints by a path prefix and anonymous middleware.
    /// All endpoints added in the `configure` closure will be prefixed and 
    /// run through the given middleware closure.
    ///
    /// - Parameters:
    ///   - pathPrefix: The path prefix for all routes defined in `configure`.
    ///   - middleware: The middleware closure which will handle
    ///     all requests to this application.
    ///   - configure: A closure for adding endpoints that will be
    ///     intercepted by the given `Middleware`.
    @discardableResult
    public func grouping(_ pathPrefix: String? = nil, middleware: @escaping Middleware.Handler, configure: (Router) -> Void) -> Self {
        configure(group(middlewares: [AnonymousMiddleware(handler: middleware)]))
        return self
    }
}
