import NIO

struct HTTPRouterResponder: HTTPResponder {
    @Inject var router: HTTPRouter
    
    func respond(to request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        print("Received request `\(request.head.method.rawValue) \(request.head.uri)`.")
        do {
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
