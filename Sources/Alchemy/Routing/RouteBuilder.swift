public protocol RouteBuilder {
    func addHandler(matcher: Matcher, middlewares: [Middleware], options: RouteOptions, handler: @escaping (Request) async throws -> Response)
    func addMiddlewares(_ middlewares: [Middleware])
    func addGroup(prefix: String, middlewares: [Middleware]) -> RouteBuilder
}

public struct RouteOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let stream = RouteOptions(rawValue: 1 << 0)
}

extension Application {
    public func addHandler(matcher: @escaping (Request) -> Bool, middlewares: [Middleware], options: RouteOptions, handler: @escaping (Request) async throws -> Response) {
        fatalError()
    }
    
    public func addMiddlewares(_ middlewares: [Middleware]) {
        fatalError()
    }
    
    public func addGroup(prefix: String, middlewares: [Middleware]) -> RouteBuilder {
        fatalError()
    }
}
