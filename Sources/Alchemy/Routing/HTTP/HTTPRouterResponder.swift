import Fusion
import NIO

struct HTTPRouterResponder: HTTPResponder {
    @Inject var router: HTTPRouter
    @Inject var globalMiddlewares: GlobalMiddlewares
    
    func respond(to request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        catchError {
            self.globalMiddlewares
                .run(on: request)
                .flatMap { request in
                    guard let response = self.router.handle(request: request) else {
                        return Loop.future(value: HTTPResponse(status: .notFound, body: nil))
                    }
                    
                    return response.throwingFlatMap { try $0.encode() }
                }
        }
    }
}
