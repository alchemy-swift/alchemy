import NIO

extension Empty: HTTPResponseEncodable {}

public extension HTTPRouter {
    /// Register an Endpoint.
    func register<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                            use closure: @escaping (HTTPRequest, Req) throws -> EventLoopFuture<Res>)
        where Req: Decodable, Res: HTTPResponseEncodable
    {
        self.registerRequest(endpoint) {
            try closure($0, try Req(from: HTTPRequestDecoder(request: $0, keyMappingStrategy: .convertToSnakeCase)))
        }
    }
    
    /// Register an Endpoint with Empty request type.
    func register<Res>(_ endpoint: Endpoint<Empty, Res>,
                       use closure: @escaping (HTTPRequest) throws -> EventLoopFuture<Res>) where Res: HTTPResponseEncodable
    {
        self.registerRequest(endpoint, closure)
    }
    
    /// Register an Endpoint with a `Void` response type.
    func register<Req>(_ endpoint: Endpoint<Req, Empty>,
                       use closure: @escaping (HTTPRequest, Req) throws -> EventLoopFuture<Void>) where Req: Decodable
    {
        self.registerRequest(endpoint) {
            try closure($0, try Req(from: HTTPRequestDecoder(request: $0, keyMappingStrategy: .convertToSnakeCase)))
                .map { Empty() }
        }
    }
    
    private func registerRequest<Req, Res>(_ endpoint: Endpoint<Req, Res>,
                                           _ closure: @escaping (HTTPRequest) throws -> EventLoopFuture<Res>)
        where Res: HTTPResponseEncodable
    {
        self.on(endpoint.method, at: endpoint.basePath, do: closure)
    }
}
