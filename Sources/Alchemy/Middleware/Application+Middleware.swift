extension Application {
    /// A closure that represents an anonymous middleware.
    public typealias MiddlewareClosure = (Request, (Request) async throws -> Response) async throws -> Response
    
    /// Applies a middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middlewares: The middlewares which will handle
    ///   all requests to this application.
    /// - Returns: This Application for chaining.
    @discardableResult
    public func useAll(_ middlewares: Middleware...) -> Self {
        Routes.globalMiddlewares.append(contentsOf: middlewares)
        return self
    }
    
    /// Applies an middleware to all requests that come through the
    /// application, whether they are handled or not.
    ///
    /// - Parameter middleware: The middleware closure which will handle
    ///   all requests to this application.
    /// - Returns: This Application for chaining.
    @discardableResult
    public func useAll(_ middleware: @escaping MiddlewareClosure) -> Self {
        Routes.globalMiddlewares.append(AnonymousMiddleware(action: middleware))
        return self
    }
    
    /// Adds middleware that will handle before all subsequent
    /// handlers.
    ///
    /// - Parameter middlewares: The middlewares.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middlewares: Middleware...) -> Self {
        Routes.middlewares.append(contentsOf: middlewares)
        return self
    }
    
    /// Adds middleware that will handle before all subsequent
    /// handlers.
    ///
    /// - Parameter middlewares: The middlewares.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middlewares: [Middleware]) -> Self {
        Routes.middlewares.append(contentsOf: middlewares)
        return self
    }
    
    /// Adds a middleware that will handle before all subsequent handlers.
    ///
    /// - Parameter middlewares: The middleware closure which will handle
    ///   all requests to this application.
    /// - Returns: This application for chaining.
    @discardableResult
    public func use(_ middleware: @escaping MiddlewareClosure) -> Self {
        Routes.middlewares.append(AnonymousMiddleware(action: middleware))
        return self
    }
    
    /// Groups a set of endpoints by a middleware. This middleware
    /// will handle all endpoints added in the `configure`
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
        snapshotMiddleware {
            $0.use(middlewares)
            configure(self)
        }
    }
    
    /// Groups a set of endpoints by a middleware. This middleware
    /// will handle all endpoints added in the `configure`
    /// closure, but none in the handler chain that
    /// continues after the `.group`.
    ///
    /// - Parameters:
    ///   - middleware: The middleware closure which will handle
    ///   all requests to this application.
    ///   - configure: A closure for adding endpoints that will be
    ///     intercepted by the given `Middleware`.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func group(middleware: @escaping MiddlewareClosure, configure: (Application) -> Void) -> Self {
        snapshotMiddleware {
            $0.use(AnonymousMiddleware(action: middleware))
            configure($0)
        }
    }
}

extension Application {
    /// Runs the action on this application. When the closure is finished, this
    /// reverts the router middleware stack back to what it was before running
    /// the action.
    @discardableResult
    func snapshotMiddleware(_ action: (Application) -> Void) -> Self {
        let middlewaresBefore = Routes.middlewares.count
        action(self)
        Routes.middlewares = Array(Routes.middlewares.prefix(middlewaresBefore))
        return self
    }
}

fileprivate struct AnonymousMiddleware: Middleware {
    let action: Application.MiddlewareClosure
    
    func handle(_ request: Request, next: (Request) async throws -> Response) async throws -> Response {
        try await action(request, next)
    }
}
