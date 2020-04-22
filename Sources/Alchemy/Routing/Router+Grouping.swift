extension Router {
    @discardableResult
    public func path(_ path: String) -> Self {
        fatalError()
//        let next = Router(uri: self.uri + path) { try self.middleware($0) }
//        self._next.value = next
//        return next
    }

    @discardableResult
    public func group(path: String? = nil, configure: (Self) -> Void) -> Self {
        self
    }

    @discardableResult
    public func group<M: Middleware>(with: M, configure: (Router<Input, Output>) -> Void) -> Self where M.Result == Void {
        self
    }

    @discardableResult
    public func group<M: Middleware>(with: M, configure: (Router<(Input, M.Result), Output>) -> Void) -> Self {
        self
    }
}
