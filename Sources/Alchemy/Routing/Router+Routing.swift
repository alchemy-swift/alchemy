import NIOHTTP1

extension Router {
    /// For values
    @discardableResult
    public func on(_ method: HTTPMethod, at path: String = "",
                   do action: @escaping (Input) throws -> Output) -> Self {
        self.add(handler: action, for: method, path: path)
        return self
    }
}

extension Router where Output == HTTPResponseEncodable {
    /// For `Void` since `Void` can't conform to any protocol.
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
}
