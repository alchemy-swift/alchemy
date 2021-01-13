// Passthroughs on application to `Services.router`.
extension Application {
    /// Applies a middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middleware: The middleware which will intercept
    ///   all requests to this application.
    /// - Returns: This Application for chaining.
    @discardableResult
    public func useAll<M: Middleware>(_ middleware: M) -> Self {
        Services.router.globalMiddlewares.append(middleware)
        return self
    }
    
    /// Adds a middleware that will intercept before all subsequent
    /// handlers.
    ///
    /// - Parameter middleware: The middleware.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use<M: Middleware>(_ middleware: M) -> Self {
        Services.router.middlewares.append(middleware)
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
        Services.router.middlewares.append(middleware)
        configure(self)
        _ = Services.router.middlewares.popLast()
        return self
    }
}
