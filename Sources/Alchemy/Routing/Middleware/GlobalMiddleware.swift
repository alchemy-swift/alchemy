import Fusion
import NIO

public final class GlobalMiddlewares {
    private var erasedMiddlewares: [(HTTPRequest) -> EventLoopFuture<HTTPRequest>] = []
    
    public func add<M: Middleware>(_ middleware: M) {
        self.erasedMiddlewares.append { middleware.intercept($0) }
    }
    
    func run(on request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
        var returnFuture = request.eventLoop.future(request)
        for middleware in self.erasedMiddlewares {
            returnFuture = returnFuture.flatMap { middleware($0) }
        }
        return returnFuture
    }
}

extension GlobalMiddlewares: SingletonService {
    public static func singleton(in container: Container) throws -> GlobalMiddlewares {
        GlobalMiddlewares()
    }
}
