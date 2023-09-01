extension Application {

    // MARK: Error Handlers

    /// Set a custom handler for when a handler isn't found for a request.
    ///
    /// - Parameter handler: The handler that returns a custom not found
    ///   response.
    @discardableResult
    public func notFoundHandler(use handler: @escaping Router.Handler) -> Self {
        @Inject var _handler: RequestHandler
        _handler.setNotFoundHandler(handler)
        return self
    }

    /// Set a custom handler for when an internal error happens while handling
    /// a request.
    ///
    /// - Parameter handler: The handler that returns a custom internal error
    ///   response.
    @discardableResult
    public func errorHandler(use handler: @escaping Router.ErrorHandler) -> Self {
        @Inject var _handler: RequestHandler
        _handler.setErrorHandler(handler)
        return self
    }

    // MARK: Global Middleware

    /// Applies a middleware to all requests that come through the application,
    /// whether they are handled or not.
    ///
    /// - Parameter middlewares: The middlewares which will handle all requests
    ///   to this application.
    @discardableResult
    public func useAll(_ middlewares: Middleware...) -> Self {
        @Inject var _handler: RequestHandler
        _handler.appendGlobalMiddlewares(middlewares)
        return self
    }

    /// Applies an middleware to all requests that come through the application,
    /// whether they are handled or not.
    ///
    /// - Parameter middlewareHandler: The middleware closure which will handle
    ///   all requests to this application.
    @discardableResult
    public func useAll(_ middlewareHandler: @escaping Middleware.Handler) -> Self {
        useAll(AnonymousMiddleware(handler: middlewareHandler))
    }

    // MARK: Router

    public func appendRoute(matcher: RouteMatcher, options: RouteOptions, middlewares: [Middleware], handler: @escaping Handler) {
        Routes.appendRoute(matcher: matcher, options: options, middlewares: middlewares, handler: handler)
    }
    
    public func appendMiddlewares(_ middlewares: [Middleware]) {
        Routes.appendMiddlewares(middlewares)
    }
    
    public func appendGroup(prefixes: [String], middlewares: [Middleware]) -> Router {
        Routes.appendGroup(prefixes: prefixes, middlewares: middlewares)
    }
}
