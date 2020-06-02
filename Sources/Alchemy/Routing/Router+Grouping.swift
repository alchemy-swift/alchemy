extension HTTPRouter {
    @discardableResult
    public func group(path: String, configure: (HTTPRouter) -> Void) -> HTTPRouter {
        configure(self.path(path))
        return self
    }

    @discardableResult
    public func group<M: Middleware>(middleware: M, configure: (HTTPRouter) -> Void) -> HTTPRouter {
        configure(self.middleware(middleware))
        return self
    }
}
