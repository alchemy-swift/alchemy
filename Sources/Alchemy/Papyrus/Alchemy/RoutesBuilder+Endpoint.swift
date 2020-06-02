import NIO

extension Empty: HTTPResponseEncodable {}

public extension HTTPRouter {
    /// Register an Endpoint.
    func register<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                            use closure: @escaping (HTTPRequest, Req) throws -> EventLoopFuture<Res>)
        where Req: RequestCodable, Res: HTTPResponseEncodable
    {
        self.registerRequest(endpoint) {
            try closure($0, try $0.load(Req.self))
        }
    }
    
    /// Register an Endpoint with Empty request type.
    func register<Res>(_ endpoint: Endpoint<Empty, Res>,
                       use closure: @escaping (HTTPRequest) throws -> EventLoopFuture<Res>) where Res: HTTPResponseEncodable
    {
        self.registerRequest(endpoint, closure)
    }
    
    private func registerRequest<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                                           _ closure: @escaping (HTTPRequest) throws -> EventLoopFuture<Res>)
        where Res: HTTPResponseEncodable
    {
        self.on(endpoint.method, at: endpoint.basePath, do: closure)
    }
}
