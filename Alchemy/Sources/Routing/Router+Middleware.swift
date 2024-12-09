extension Router {

    /// Adds middleware to this router. All subsequent handlers added to the
    /// router will go through this middleware(s).
    ///
    /// - Parameter middlewares: The middlewares.
    @discardableResult
    public func use(_ middlewares: Middleware...) -> Self {
        appendMiddlewares(middlewares)
        return self
    }

    /// Adds an array of middlewares to this router.
    ///
    /// - Parameter middlewares: The middlewares.
    @discardableResult
    public func use(_ middlewares: [Middleware]) -> Self {
        appendMiddlewares(middlewares)
        return self
    }

    /// Adds an anonymous middleware to this router.
    ///
    /// - Parameter middlewares: The middleware closure which will handle all
    ///   requests to this application.
    @discardableResult
    public func use(_ middlewareHandler: @escaping Middleware.Handler) -> Self {
        appendMiddlewares([AnonymousMiddleware(handler: middlewareHandler)])
        return self
    }
}
