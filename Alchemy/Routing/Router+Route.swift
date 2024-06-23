extension Router {
    @discardableResult public func use(_ route: Route) -> Self {
        on(route.method, at: route.path, options: route.options, use: route.handler)
        return self
    }
}

public struct Route {
    public let method: HTTPMethod
    public let path: String
    public var options: RouteOptions
    public let handler: (Request) async throws -> ResponseConvertible

    public init(method: HTTPMethod, path: String, options: RouteOptions = [], handler: @escaping (Request) async throws -> ResponseConvertible) {
        self.method = method
        self.path = path
        self.options = options
        self.handler = handler
    }

    public init(method: HTTPMethod, path: String, options: RouteOptions = [], handler: @escaping (Request) async throws -> Void) {
        self.method = method
        self.path = path
        self.options = options
        self.handler = { req in
            try await handler(req)
            return Response(status: .ok)
        }
    }

    public init<E: Encodable>(method: HTTPMethod, path: String, options: RouteOptions = [], handler: @escaping (Request) async throws -> E) {
        self.method = method
        self.path = path
        self.options = options
        self.handler = { req in
            let value = try await handler(req)
            if let convertible = value as? ResponseConvertible {
                return try await convertible.response()
            } else {
                return try Response(status: .ok, encodable: value)
            }
        }
    }
}
