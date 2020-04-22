import NIO

struct HTTPRouterResponder: HTTPResponder {
    @Inject var router: HTTPRouter
    
    func respond(to request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        print("Request was: \(request.head.method.rawValue) \(request.head.uri)")
        
        guard let response = try? self.router.handle(request: request) else {
            return request.eventLoop
                .makeSucceededFuture(HTTPResponse(status: .notFound, body: nil))
        }
        
        return request.eventLoop.makeSucceededFuture(response)
    }
}
