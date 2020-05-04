public final class GlobalMiddlewares {
    private var erasedMiddlewares: [(HTTPRequest) throws -> Void] = []
    
    public func add<M: Middleware>(_ middleware: M) {
        self.erasedMiddlewares.append { _ = try middleware.intercept($0) }
    }
    
    func run(on request: HTTPRequest) throws {
        for middleware in self.erasedMiddlewares {
            try middleware(request)
        }
    }
}

extension GlobalMiddlewares: SingletonService {
    public static func singleton(in container: Container) throws -> GlobalMiddlewares {
        GlobalMiddlewares()
    }
}
