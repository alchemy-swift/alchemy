extension Router {
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: The method of requests this handler will handle.
    ///   - path: The path this handler expects. Dynamic path parameters should
    ///     be prefaced with a `:` (See `Request.Parameter`).
    ///   - options: The options for this route, to enable streaming.
    ///   - middlewares: Any middlewares to apply to this route.
    ///   - handler: The handler to respond to the request with.
    /// - Returns: This application for building a handler chain.
    @discardableResult
    public func on(_ method: HTTPRequest.Method, at path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        let matcher = RouteMatcher(path: path, match: { $0.method == method })
        appendRoute(matcher: matcher, options: options, middlewares: middlewares, handler: handler)
        return self
    }

    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        on(.get, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        on(.post, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        on(.put, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        on(.patch, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        on(.delete, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        on(.options, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping Router.Handler) -> Self {
        on(.head, at: path, options: options, middlewares: middlewares, use: handler)
    }

    // MARK: - Sugar

    // The following are all sugar for defining handlers, since it's not
    // possible to conform all handler return types we wish to support
    // to `ResponseConvertible`.
    //
    // Specifically, these extensions support having `Void` and `Encodable` as
    // handler return types.

    // MARK: Void

    /// A route handler that returns `Void`.
    public typealias VoidHandler = (Request) async throws -> Void

    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: The method of requests this handler will handle.
    ///   - path: The path this handler expects. Dynamic path parameters should
    ///     be prefaced with a `:` (See `Parameter`).
    ///   - options: The options for this route, to enable streaming.
    ///   - middlewares: Any middlewares to apply to this route.
    ///   - handler: The handler to respond to the request with.
    /// - Returns: This application for building a handler chain.
    @discardableResult
    public func on(_ method: HTTPRequest.Method, at path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(method, at: path, options: options, middlewares: middlewares) {
            try await handler($0)
            return Response(status: .ok, body: nil)
        }
    }

    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(.get, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(.post, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(.put, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(.patch, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(.delete, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(.options, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping VoidHandler) -> Self {
        on(.head, at: path, options: options, middlewares: middlewares, use: handler)
    }

    // MARK: Encodable

    /// A route handler that returns some `Encodable`.
    public typealias EncodableHandler<E: Encodable> = (Request) async throws -> E

    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: The method of requests this handler will handle.
    ///   - path: The path this handler expects. Dynamic path parameters should
    ///     be prefaced with a `:` (See `Parameter`).
    ///   - options: The options for this route, to enable streaming.
    ///   - middlewares: Any middlewares to apply to this route.
    ///   - handler: The handler to respond to the request with.
    /// - Returns: This application for building a handler chain.
    @discardableResult
    public func on(_ method: HTTPRequest.Method, at path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(method, at: path, options: options, middlewares: middlewares) { req -> Response in
            let value = try await handler(req)
            if let convertible = value as? ResponseConvertible {
                return try await convertible.response()
            } else {
                return try Response(status: .ok, encodable: value)
            }
        }
    }

    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(.get, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(.post, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(.put, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(.patch, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(.delete, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(.options, at: path, options: options, middlewares: middlewares, use: handler)
    }

    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String? = nil, options: RouteOptions = [], middlewares: [Middleware] = [], use handler: @escaping EncodableHandler<some Encodable>) -> Self {
        on(.head, at: path, options: options, middlewares: middlewares, use: handler)
    }
}
