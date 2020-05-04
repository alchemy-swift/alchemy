import NIO

struct HTTPRouterResponder: HTTPResponder {
    @Inject var router: HTTPRouter
    @Inject var globalMiddlewares: GlobalMiddlewares
    
    func respond(to request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        do {
            try self.globalMiddlewares.run(on: request)
            guard let response = try self.router.handle(request: request) else {
                return request.eventLoop
                    .makeSucceededFuture(HTTPResponse(status: .notFound, body: nil))
            }
            
            return try response.encode(on: request.eventLoop)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}
