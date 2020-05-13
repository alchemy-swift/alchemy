import NIO

extension Empty: HTTPResponseEncodable {}

public extension HTTPRouter {
    /// Register an Endpoint.
    func register<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                            use closure: @escaping (HTTPRequest, Req) throws -> Res)
        where Req: RequestLoadable, Res: HTTPResponseEncodable
    {
        let wrappingClosure = { (request: HTTPRequest) -> Res in
            try closure(request, try request.load(Req.self))
        }
        registerRequest(endpoint, wrappingClosure)
    }
    
    /// Register an Endpoint with Empty request type.
    func register<Res>(_ endpoint: Endpoint<Empty, Res>,
                       use closure: @escaping (HTTPRequest) throws -> Res) where Res: HTTPResponseEncodable
    {
        registerRequest(endpoint, closure)
    }
    
    private func registerRequest<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                                           _ closure: @escaping (HTTPRequest) throws -> Res)
        where Res: HTTPResponseEncodable
    {
        self.on(endpoint.method, at: endpoint.basePath, do: closure)
    }
}
