extension Application {
    /// A closure that represents an anonymous middleware.
    public typealias MiddlewareClosure = (Request, (Request) async throws -> Response) async throws -> Response
    
    /// Applies a middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middlewares: The middlewares which will intercept
    ///   all requests to this application.
    /// - Returns: This Application for chaining.
    @discardableResult
    public func useAll(_ middlewares: Middleware...) -> Self {
        router.globalMiddlewares.append(contentsOf: middlewares)
        return self
    }
    
    /// Applies an middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middleware: The middleware closure which will intercept
    ///   all requests to this application.
    /// - Returns: This Application for chaining.
    @discardableResult
    public func useAll(_ middleware: @escaping MiddlewareClosure) -> Self {
        router.globalMiddlewares.append(AnonymousMiddleware(action: middleware))
        return self
    }
    
    /// Adds middleware that will intercept before all subsequent
    /// handlers.
    ///
    /// - Parameter middlewares: The middlewares.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middlewares: Middleware...) -> Self {
        router.middlewares.append(contentsOf: middlewares)
        return self
    }
    
    /// Adds a middleware that will intercept before all subsequent handlers.
    ///
    /// - Parameter middlewares: The middleware closure which will intercept
    ///   all requests to this application.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middleware: @escaping MiddlewareClosure) -> Self {
        router.middlewares.append(AnonymousMiddleware(action: middleware))
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
    public func group(_ middlewares: Middleware..., configure: (Application) -> Void) -> Self {
        router.middlewares.append(contentsOf: middlewares)
        configure(self)
        _ = router.middlewares.popLast()
        return self
    }
    
    /// Groups a set of endpoints by a middleware. This middleware
    /// will intercept all endpoints added in the `configure`
    /// closure, but none in the handler chain that
    /// continues after the `.group`.
    ///
    /// - Parameters:
    ///   - middleware: The middleware closure which will intercept
    ///   all requests to this application.
    ///   - configure: A closure for adding endpoints that will be
    ///     intercepted by the given `Middleware`.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func group(middleware: @escaping MiddlewareClosure, configure: (Application) -> Void) -> Self {
        router.middlewares.append(AnonymousMiddleware(action: middleware))
        configure(self)
        _ = router.middlewares.popLast()
        return self
    }
}

fileprivate struct AnonymousMiddleware: Middleware {
    let action: Application.MiddlewareClosure
    
    func intercept(_ request: Request, next: (Request) async throws -> Response) async throws -> Response {
        try await action(request, next)
    }
}
