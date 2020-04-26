extension Router {
    @discardableResult
    public func group(path: String, configure: (Router<Input, Output>) -> Void) -> Self {
        configure(self.path(path))
        return self
    }

    @discardableResult
    public func group<M: Middleware>(middleware: M, configure: (Router<Input, Output>) -> Void) -> Self where M.Result == Void {
        configure(self.middleware(middleware))
        return self
    }

    @discardableResult
    public func group<M: Middleware>(middleware: M, configure: (Router<(Input, M.Result), Output>) -> Void) -> Self {
        configure(self.middleware(middleware))
        return self
    }
}
