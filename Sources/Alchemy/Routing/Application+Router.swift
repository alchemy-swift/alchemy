// Passthroughs on application to `Services.router`.
extension Application {
    /// Applies a middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middleware: the middleware which will intercept
    /// all requests to this application.
    /// - Returns: the new router with the middleware.
    public func useAll<M: Middleware>(_ middleware: M) -> Self {
        Services.router.use(middleware)
        return self
    }
    
    /// Returns a new router, a child of this one, that will apply the given middleware to any
    /// requests handled by it.
    ///
    /// - Parameter middleware: the middleware which will intercept all requests on this new router.
    /// - Returns: the new router with the middleware.
    public func use<M: Middleware>(_ middleware: M) -> Self {
        Services.router.use(middleware)
        return self
    }

    /// Returns a new router, a child of this one, that will prepend the given string to the URIs of
    /// all it's handlers.
    ///
    /// - Parameter path: the string to prepend to the URIs of all the new router's handlers.
    /// - Returns: the newly created `Router`, a child of `self`.
    public func path(_ path: String) -> Self {
        Services.router.path(path)
        return self
    }
}
