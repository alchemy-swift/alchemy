import NIO
import NIOHTTP1

extension Router {
    @discardableResult
    public func on(_ method: HTTPMethod, at path: String = "",
                   do action: @escaping (Input) throws -> Output) -> Self {
        self.add(handler: action, for: method, path: path)
        return self
    }
}

/// `Void` sugar, since `Void` can't conform to a protocol.
extension Router where Output == HTTPResponseEncodable {
    /// For `Void`.
    @discardableResult
    public func on(_ method: HTTPMethod, at path: String = "",
                   do action: @escaping (Input) throws -> Void) -> Self {
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
    
    /// For `EventLoopFuture<Void>`.
    @discardableResult
    public func on(_ method: HTTPMethod, at path: String = "",
                   do action: @escaping (Input) throws -> EventLoopFuture<Void>) -> Self {
        self.add(handler: { try action($0).map { VoidCodable() } }, for: method, path: path)
        return self
    }
}

/// `Codable` sugar; protocol extensions can't have inheritence clauses so we can't conform
/// `Codable` to `HTTPResponseEncodable`.
extension Router where Output == HTTPResponseEncodable {
    /// For `Codable`.
    @discardableResult
    public func on<E: Encodable>(
        _ method: HTTPMethod,
        at path: String = "",
        do action: @escaping (Input) throws -> E
    ) -> Self {
        self.add(handler: { CodableWrapper(obj: try action($0)) }, for: method, path: path)
        return self
    }
    
    /// For `EventLoopFuture<E: Encodable>`.
    @discardableResult
    public func on<E: Encodable>(
        _ method: HTTPMethod,
        at path: String = "",
        do action: @escaping (Input) throws -> EventLoopFuture<E>
    ) -> Self {
        self.add(handler: { try action($0).map(CodableWrapper.init) }, for: method, path: path)
        return self
    }
}
