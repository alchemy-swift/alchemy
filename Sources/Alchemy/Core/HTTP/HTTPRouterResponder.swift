import Fusion
import NIO

/// Used for responding to all incoming `HTTPRequest`s in a serving `Application`.
struct HTTPRouterResponder: HTTPResponder {
    /// The global, singleton router.
    @Inject var router: Router
    
    // MARK: HTTPResponder
    
    func respond(to request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        Router.globalMiddlewares
            // First apply global middlewares, in order.
            .reduce(EventLoopFuture<HTTPRequest>.new(request)) {
                $0.flatMap($1.intercept)
            }
            // Then, send to the router.
            .flatMap { request in
                guard let response = self.router.handle(request: request) else {
                    // If the router doesn't handle the request, return a 404.
                    return .new(HTTPResponse(status: .notFound, body: nil))
                }
                
                // If the router CAN handle the request, turn the returned
                // `HTTPResponseEncodable` into an `HTTPResponse`.
                return response.flatMap { res in
                    catchError { try res.encode() }
                }
            }
    }
}
