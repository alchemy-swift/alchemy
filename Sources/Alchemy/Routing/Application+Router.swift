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
        Services.router.use(middleware)
        return self
    }
    
    /// Returns a new router, a child of this one, that will apply the given middleware to any
    /// requests handled by it.
    ///
    /// - Parameter middleware: the middleware which will intercept all requests on this new router.
    /// - Returns: the new router with the middleware.
    @discardableResult
    public func use<M: Middleware>(_ middleware: M) -> Self {
        Services.router.use(middleware)
        return self
    }
    
    func popMiddleware() {
        Services.router.popMiddleware()
    }
}
