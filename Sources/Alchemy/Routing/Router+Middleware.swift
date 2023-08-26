extension Router {

    /// Adds middleware that will handle before all subsequent
    /// handlers.
    ///
    /// - Parameter middlewares: The middlewares.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middlewares: Middleware...) -> Self {
        appendMiddlewares(middlewares)
        return self
    }

    /// Adds middleware that will handle before all subsequent
    /// handlers.
    ///
    /// - Parameter middlewares: The middlewares.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middlewares: [Middleware]) -> Self {
        appendMiddlewares(middlewares)
        return self
    }

    /// Adds a middleware that will handle before all subsequent handlers.
    ///
    /// - Parameter middlewares: The middleware closure which will handle
    ///   all requests to this application.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middlewareHandler: @escaping Middleware.Handler) -> Self {
        appendMiddlewares([AnonymousMiddleware(handler: middlewareHandler)])
        return self
    }
}
