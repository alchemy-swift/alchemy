// Passthroughs on application to `Services.router`.
extension Application {
    /// Applies a middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middleware: the middleware which will intercept
    /// all requests to this application.
    /// - Returns: the new router with the middleware.
    @discardableResult
    public func useAll<M: Middleware>(_ middleware: M) -> Self {
        Services.router.globalMiddlewares.append(middleware)
        return self
    }
    
    /// Returns a new router, a child of this one, that will apply the given middleware to any
    /// requests handled by it.
    ///
    /// - Parameter middleware: the middleware which will intercept all requests on this new router.
    /// - Returns: the new router with the middleware.
    @discardableResult
    public func use<M: Middleware>(_ middleware: M) -> Self {
        Services.router.middlewares.append(middleware)
        return self
    }
    
    /// Groups a set of endpoints by a middleware. This middleware will intercept all endpoints
    /// added to the `configure` parameter, but none in the request chain that continues after the
    /// `.group`.
    ///
    /// - Parameters:
    ///   - middleware: the middleware for intercepting requests defined on the closure parameter.
    ///   - configure: a closure for adding endpoints that will be intercepted by the given
    ///                `Middleware`.
    /// - Returns: a router to continue building the handler chain. This router will NOT intercept
    ///            request with the given `middleware`, unlike `Router.middleware(...)`.
    @discardableResult
    public func group<M: Middleware>(middleware: M, configure: (Application) -> Void) -> Self {
        Services.router.middlewares.append(middleware)
        configure(self)
        _ = Services.router.middlewares.popLast()
        return self
    }
}
