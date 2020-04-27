public final class GlobalMiddlewares: Injectable {
    private var erasedMiddlewares: [(HTTPRequest) throws -> Void] = []
    
    public func add<M: Middleware>(_ middleware: M) {
        self.erasedMiddlewares.append { _ = try middleware.intercept($0) }
    }
    
    func run(on request: HTTPRequest) throws {
        for middleware in self.erasedMiddlewares {
            try middleware(request)
        }
    }
    
    public static func create(_ isMock: Bool) -> GlobalMiddlewares {
        struct Shared {
            static let storage = GlobalMiddlewares()
        }
        
        return Shared.storage
    }
}
