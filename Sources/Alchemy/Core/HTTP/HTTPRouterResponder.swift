import Fusion
import NIO

/// Used for responding to all incoming `Request`s in a serving `Application`.
struct HTTPRouterResponder: HTTPResponder {
    /// The global, singleton router.
    @Inject var router: Router
    
    // MARK: HTTPResponder
    
    func respond(to request: Request) -> EventLoopFuture<Response> {
        var handlerClosure = self.router.handle
        
        for middleware in self.router.globalMiddlewares.reversed() {
            let lastHandler = handlerClosure
            handlerClosure = { request in
                middleware.intercept(request, next: lastHandler)
            }
        }
        
        return handlerClosure(request)
    }
}
