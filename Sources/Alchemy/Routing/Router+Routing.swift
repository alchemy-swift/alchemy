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

/// `Void` helpers, since `Void` can't conform to a protocol.
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
