extension Application {
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
        configure(self.use(middleware))
        self.popMiddleware()
        return self
    }
}
