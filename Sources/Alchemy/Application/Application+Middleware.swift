// Passthroughs on application to `Services.router`.
extension Application {
    /// Applies a middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middlewares: The middlewares which will intercept
    ///   all requests to this application.
    /// - Returns: This Application for chaining.
    @discardableResult
    public func useAll(_ middlewares: Middleware...) -> Self {
        Router.default.globalMiddlewares.append(contentsOf: middlewares)
        return self
    }
    
    /// Adds middleware that will intercept before all subsequent
    /// handlers.
    ///
    /// - Parameter middlewares: The middlewares.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middlewares: Middleware...) -> Self {
        Router.default.middlewares.append(contentsOf: middlewares)
        return self
    }
    
    /// Groups a set of endpoints by a middleware. This middleware
    /// will intercept all endpoints added in the `configure`
    /// closure, but none in the handler chain that
    /// continues after the `.group`.
    ///
    /// - Parameters:
    ///   - middleware: The middleware for intercepting requests
    ///     defined in the `configure` closure.
    ///   - configure: A closure for adding endpoints that will be
    ///     intercepted by the given `Middleware`.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func group<M: Middleware>(middleware: M, configure: (Application) -> Void) -> Self {
        Router.default.middlewares.append(middleware)
        configure(self)
        _ = Router.default.middlewares.popLast()
        return self
    }
}
