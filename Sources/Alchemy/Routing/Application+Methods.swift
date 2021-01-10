import NIO
import NIOHTTP1

extension Application {
    /// A basic route handler closure. Most types you'll need conform to `ResponseConvertible` out
    /// of the box.
    public typealias Handler = (Request) throws -> ResponseConvertible
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: the method of requests this handler will handle.
    ///   - path: the path this handler expects. Dynamic path parameters should be prefaced with a
    ///           `:` (See `PathParameter`).
    ///   - handler: the handler to respond to a matching request with.
    /// - Returns: this router for continuing to build a handler chain.
    @discardableResult
    public func on(
        _ method: HTTPMethod,
        at path: String = "",
        handler: @escaping Handler
    ) -> Self {
        Services.router.add(handler: handler, for: method, path: path)
        return self
    }
    
    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String = "", handler: @escaping Handler) -> Self {
        self.on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String = "", handler: @escaping Handler) -> Self {
        self.on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String = "", handler: @escaping Handler) -> Self {
        self.on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String = "", handler: @escaping Handler) -> Self {
        self.on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String = "", handler: @escaping Handler) -> Self {
        self.on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String = "", handler: @escaping Handler) -> Self {
        self.on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String = "", handler: @escaping Handler) -> Self {
        self.on(.HEAD, at: path, handler: handler)
    }
}

/// These extensions are all sugar for defining handlers, since it's not possible to conform all
/// handler return types we wish to support to `ResponseConvertible`.
///
/// Specifically, these extensions support having `Void`, `EventLoopFuture<Void>`, `E: Encodable`,
/// and `EventLoopFuture<E: Encodable>` as handler return types.
///
/// This extension is pretty bulky because we need each of these four for `on` & each method.
extension Application {

    // MARK: - Void
    
    /// A route handler that returns `Void`.
    public typealias VoidHandler = (Request) throws -> Void
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: the method of requests this handler will handle.
    ///   - path: the path this handler expects. Dynamic path parameters should be prefaced with a
    ///           `:` (See `PathParameter`).
    ///   - action: the handler to respond to a matching request with.
    /// - Returns: this router for continuing to build a handler chain.
    @discardableResult
    public func on(
        _ method: HTTPMethod,
        at path: String = "",
        handler: @escaping VoidHandler
    ) -> Self {
        self.on(method, at: path, handler: { out -> VoidResponse in
            try handler(out)
            return VoidResponse()
        })
    }
    
    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        self.on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        self.on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        self.on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        self.on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        self.on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        self.on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String = "", handler: @escaping VoidHandler) -> Self {
        self.on(.HEAD, at: path, handler: handler)
    }
    
    // MARK: - EventLoopFuture<Void>
    
    /// A route handler that returns an `EventLoopFuture<Void>`.
    public typealias VoidFutureHandler = (Request) throws -> EventLoopFuture<Void>
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: the method of requests this handler will handle.
    ///   - path: the path this handler expects. Dynamic path parameters should be prefaced with a
    ///           `:` (See `PathParameter`).
    ///   - action: the handler to respond to a matching request with.
    /// - Returns: this router for continuing to build a handler chain.
    @discardableResult
    public func on(
        _ method: HTTPMethod,
        at path: String = "",
        handler: @escaping VoidFutureHandler
    ) -> Self {
        self.on(method, at: path, handler: { try handler($0).map { VoidResponse() } })
    }
    
    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get(_ path: String = "", handler: @escaping VoidFutureHandler) -> Self {
        self.on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post(_ path: String = "", handler: @escaping VoidFutureHandler) -> Self {
        self.on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put(_ path: String = "", handler: @escaping VoidFutureHandler) -> Self {
        self.on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch(_ path: String = "", handler: @escaping VoidFutureHandler) -> Self {
        self.on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete(_ path: String = "", handler: @escaping VoidFutureHandler) -> Self {
        self.on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options(_ path: String = "", handler: @escaping VoidFutureHandler) -> Self {
        self.on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head(_ path: String = "", handler: @escaping VoidFutureHandler) -> Self {
        self.on(.HEAD, at: path, handler: handler)
    }
    
    // MARK: - E: Encodable
    
    /// A route handler that returns some `Encodable`.
    public typealias EncodableHandler<E: Encodable> = (Request) throws -> E
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: the method of requests this handler will handle.
    ///   - path: the path this handler expects. Dynamic path parameters should be prefaced with a
    ///           `:` (See `PathParameter`).
    ///   - action: the handler to respond to a matching request with.
    /// - Returns: this router for continuing to build a handler chain.
    @discardableResult
    public func on<E: Encodable>(
        _ method: HTTPMethod, at path: String = "", handler: @escaping EncodableHandler<E>
    ) -> Self {
        self.on(method, at: path, handler: { try handler($0).encode() })
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
    
    
    // MARK: - EventLoopFuture<E: Encodable>
    
    /// A route handler that returns an `EventLoopFuture<E: Encodable>`.
    public typealias EncodableFutureHandler<E: Encodable> = (Request) throws -> EventLoopFuture<E>
    
    /// Adds a handler at a given method and path.
    ///
    /// - Parameters:
    ///   - method: the method of requests this handler will handle.
    ///   - path: the path this handler expects. Dynamic path parameters should be prefaced with a
    ///           `:` (See `PathParameter`).
    ///   - action: the handler to respond to a matching request with.
    /// - Returns: this router for continuing to build a handler chain.
    @discardableResult
    public func on<E: Encodable>(
        _ method: HTTPMethod,
        at path: String = "",
        handler: @escaping (Request) throws -> EventLoopFuture<E>
    ) -> Self {
        self.on(method, at: path, handler: { try handler($0).flatMapThrowing { try $0.encode() } })
    }
    
    /// `GET` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func get<E: Encodable>(_ path: String = "", handler: @escaping EncodableFutureHandler<E>) -> Self {
        self.on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func post<E: Encodable>(_ path: String = "", handler: @escaping EncodableFutureHandler<E>) -> Self {
        self.on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func put<E: Encodable>(_ path: String = "", handler: @escaping EncodableFutureHandler<E>) -> Self {
        self.on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func patch<E: Encodable>(_ path: String = "", handler: @escaping EncodableFutureHandler<E>) -> Self {
        self.on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func delete<E: Encodable>(_ path: String = "", handler: @escaping EncodableFutureHandler<E>) -> Self {
        self.on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func options<E: Encodable>(_ path: String = "", handler: @escaping EncodableFutureHandler<E>) -> Self {
        self.on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    @discardableResult
    public func head<E: Encodable>(_ path: String = "", handler: @escaping EncodableFutureHandler<E>) -> Self {
        self.on(.HEAD, at: path, handler: handler)
    }
}

/// Used as the response for a handler returns `Void` or `EventLoopFuture<Void>`.
private struct VoidResponse: ResponseConvertible {
    // MARK: ResponseConvertible
    
    func convert() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: nil))
    }
}
// Sadly `Swift` doesn't allow a protocol to conform to another protocol in extensions, but we can
// at least add the implementation here (and a special case router `.on` specifically for
// `Encodable`) types.
extension Encodable {
    // MARK: ResponseConvertible
    
    public func encode() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: try HTTPBody(json: self)))
    }
}
