import NIO
import NIOHTTP1

extension Application {
    /// Groups a set of endpoints by a path prefix.
    /// All endpoints added in the `configure` closure will
    /// be prefixed, but none in the handler chain that continues
    /// after the `.grouped`.
    ///
    /// - Parameters:
    ///   - pathPrefix: The path prefix for all routes
    ///     defined in the `configure` closure.
    ///   - configure: A closure for adding routes that will be
    ///     prefixed by the given path prefix.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func grouped(_ pathPrefix: String, configure: (Application) -> Void) -> Self {
        let prefixes = pathPrefix.split(separator: "/").map(String.init)
        Router.default.pathPrefixes.append(contentsOf: prefixes)
        configure(self)
        for _ in prefixes {
            _ = Router.default.pathPrefixes.popLast()
        }
        return self
    }
}

extension Application {
    /// Set a custom handler for when a handler isn't found for a
    /// request.
    ///
    /// - Parameter handler: The handler that returns a custom not
    ///   found response.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func notFound(use handler: @escaping Handler) -> Self {
        Router.default.notFoundHandler = handler
        return self
    }
    
    /// Set a custom handler for when an internal error happens while
    /// handling a request.
    ///
    /// - Parameter handler: The handler that returns a custom
    ///   internal error response.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func internalError(use handler: @escaping Router.ErrorHandler) -> Self {
        Router.default.internalErrorHandler = handler
        return self
    }
}

extension Application {
    /// A basic route handler closure. Most types you'll need conform
    /// to `ResponseConvertible` out of the box.
    public typealias Handler = (Request) async throws -> ResponseConvertible
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: The method of requests this handler will handle.
    ///   - path: The path this handler expects. Dynamic path
    ///     parameters should be prefaced with a `:`
    ///     (See `PathParameter`).
    ///   - handler: The handler to respond to the request with.
    /// - Returns: This application for building a handler chain.
    @discardableResult
    public func on(_ method: HTTPMethod, at path: String = "", handler: @escaping Handler) -> Self {
        Router.default.add(handler: handler, for: method, path: path)
        return self
    }
    
    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String = "", handler: @escaping Handler) -> Self {
        on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String = "", handler: @escaping Handler) -> Self {
        on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String = "", handler: @escaping Handler) -> Self {
        on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String = "", handler: @escaping Handler) -> Self {
        on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String = "", handler: @escaping Handler) -> Self {
        on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String = "", handler: @escaping Handler) -> Self {
        on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String = "", handler: @escaping Handler) -> Self {
        on(.HEAD, at: path, handler: handler)
    }
}

/// These extensions are all sugar for defining handlers, since it's
/// not possible to conform all handler return types we wish to
/// support to `ResponseConvertible`.
///
/// Specifically, these extensions support having `Void` and
/// `Encodable` as handler return types.
extension Application {

    // MARK: - Void
    
    /// A route handler that returns `Void`.
    public typealias VoidHandler = (Request) async throws -> Void
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: The method of requests this handler will handle.
    ///   - path: The path this handler expects. Dynamic path
    ///     parameters should be prefaced with a `:`
    ///     (See `PathParameter`).
    ///   - handler: The handler to respond to the request with.
    /// - Returns: This application for building a handler chain.
    @discardableResult
    public func on(_ method: HTTPMethod, at path: String = "", handler: @escaping VoidHandler) -> Self {
        on(method, at: path) { request -> Response in
            try await handler(request)
            return Response(status: .ok, body: nil)
        }
    }
    
    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        on(.HEAD, at: path, handler: handler)
    }

    // MARK: - E: Encodable
    
    /// A route handler that returns some `Encodable`.
    public typealias EncodableHandler<E: Encodable> = (Request) async throws -> E
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: The method of requests this handler will handle.
    ///   - path: The path this handler expects. Dynamic path
    ///     parameters should be prefaced with a `:`
    ///     (See `PathParameter`).
    ///   - handler: The handler to respond to the request with.
    /// - Returns: This application for building a handler chain.
    @discardableResult
    public func on<E: Encodable>(
        _ method: HTTPMethod, at path: String = "", handler: @escaping EncodableHandler<E>
    ) -> Self {
        on(method, at: path, handler: { try await handler($0).convert() })
    }
    
    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get<E: Encodable>(_ path: String = "", handler: @escaping EncodableHandler<E>) -> Self {
        self.on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post<E: Encodable>(_ path: String = "", handler: @escaping EncodableHandler<E>) -> Self {
        self.on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put<E: Encodable>(_ path: String = "", handler: @escaping EncodableHandler<E>) -> Self {
        self.on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch<E: Encodable>(_ path: String = "", handler: @escaping EncodableHandler<E>) -> Self {
        self.on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete<E: Encodable>(_ path: String = "", handler: @escaping EncodableHandler<E>) -> Self {
        self.on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options<E: Encodable>(_ path: String = "", handler: @escaping EncodableHandler<E>) -> Self {
        self.on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head<E: Encodable>(_ path: String = "", handler: @escaping EncodableHandler<E>) -> Self {
        self.on(.HEAD, at: path, handler: handler)
    }
}
