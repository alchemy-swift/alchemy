import NIO
import NIOHTTP1

extension Router {
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
        do action: @escaping (Request) throws -> ResponseConvertible
    ) -> Self {
        self.add(handler: action, for: method, path: path)
        return self
    }
}

/// These extensions are all sugar for defining handlers, since it's not possible to conform all
/// handler return types we wish to support to `ResponseConvertible`.
extension Router {
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
        do action: @escaping (Request) throws -> Void
    ) -> Self {
        self.add(
            handler: { out -> VoidCodable in
                try action(out)
                return VoidCodable()
            },
            for: method,
            path: path
        )
        return self
    }
    
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
        do action: @escaping (Request) throws -> EventLoopFuture<Void>
    ) -> Self {
        self.add(handler: { try action($0).map { VoidCodable() } }, for: method, path: path)
        return self
    }
    
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
        do action: @escaping (Request) throws -> E
    ) -> Self {
        self.add(handler: { try action($0).encode() }, for: method, path: path)
        return self
    }
    
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
        do action: @escaping (Request) throws -> EventLoopFuture<E>
    ) -> Self {
        self.add(
            handler: { try action($0).flatMapThrowing { try $0.encode() } },
            for: method, path: path
        )
        return self
    }
}

/// Used as the response for a handler returns `Void` or `EventLoopFuture<Void>`.
private struct VoidCodable: Codable {}

extension VoidCodable: ResponseConvertible {
    // MARK: ResponseConvertible
    
    func convert() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: try HTTPBody(json: self)))
    }
}

// Sadly `Swift` doesn't allow a protocol to conform to another protocol in extensions, but we can
// at least add the implementation here (and a special case router `.on` specifcally for
// `Encodable`) types.
extension Encodable {
    // MARK: ResponseConvertible
    
    public func encode() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: try HTTPBody(json: self)))
    }
}
