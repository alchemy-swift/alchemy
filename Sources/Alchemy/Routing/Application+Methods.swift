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
    public func get(_ path: String = "", handler: @escaping Handler) {
        self.on(.GET, at: path, handler: handler)
    }
    
    /// `POST` wrapper of `Application.on(method:path:handler:)`.
    public func post(_ path: String = "", handler: @escaping Handler) {
        self.on(.POST, at: path, handler: handler)
    }
    
    /// `PUT` wrapper of `Application.on(method:path:handler:)`.
    public func put(_ path: String = "", handler: @escaping Handler) {
        self.on(.PUT, at: path, handler: handler)
    }
    
    /// `PATCH` wrapper of `Application.on(method:path:handler:)`.
    public func patch(_ path: String = "", handler: @escaping Handler) {
        self.on(.PATCH, at: path, handler: handler)
    }
    
    /// `DELETE` wrapper of `Application.on(method:path:handler:)`.
    public func delete(_ path: String = "", handler: @escaping Handler) {
        self.on(.DELETE, at: path, handler: handler)
    }
    
    /// `OPTIONS` wrapper of `Application.on(method:path:handler:)`.
    public func options(_ path: String = "", handler: @escaping Handler) {
        self.on(.OPTIONS, at: path, handler: handler)
    }
    
    /// `HEAD` wrapper of `Application.on(method:path:handler:)`.
    public func head(_ path: String = "", handler: @escaping Handler) {
        self.on(.HEAD, at: path, handler: handler)
    }
}
