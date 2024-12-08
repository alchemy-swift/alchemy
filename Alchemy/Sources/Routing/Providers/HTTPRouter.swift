final class HTTPRouter: Router, Middleware {
    private struct Route {
        var matcher: RouteMatcher
        let options: RouteOptions
        let middlewares: [Middleware]
        let handler: (Request) async throws -> Response

        func handle(request: Request) async throws -> Response {
            try await middlewares.handle(request, next: handler)
        }
    }

    private enum Handler {
        case route(Route)
        case router(HTTPRouter)

        func route(for request: Request) -> Route? {
            switch self {
            case .route(var route):
                return route.matcher.match(request) ? route : nil
            case .router(let router):
                return router.findRoute(for: request)
            }
        }
    }

    private let prefixes: [String]
    private var middlewares: [Middleware]
    private var handlers: [Handler]

    init(prefixes: [String] = [], middlewares: [Middleware] = []) {
        self.prefixes = prefixes
        self.middlewares = middlewares
        self.handlers = []
    }

    private func findRoute(for request: Request) -> Route? {
        for handler in handlers {
            if let route = handler.route(for: request) {
                return route
            }
        }

        return nil
    }

    // MARK: Middleware

    func handle(_ request: Request, next: Next) async throws -> Response {
        if let route = findRoute(for: request) {
            request.parameters = route.matcher.parameters
            if !route.options.contains(.stream) {
                try await request.collect()
            }

            return try await route.handle(request: request)
        } else {
            return try await next(request)
        }
    }

    // MARK: Router

    func appendRoute(matcher: RouteMatcher, options: RouteOptions, middlewares: [Middleware], handler: @escaping Router.Handler) {
        let matcher = matcher.with { $0.prefixed(by: prefixes) }
        let route = Route(matcher: matcher, options: options, middlewares: self.middlewares + middlewares) { try await handler($0).response() }
        handlers.append(.route(route))
    }

    func appendMiddlewares(_ middlewares: [Middleware]) {
        self.middlewares.append(contentsOf: middlewares)
    }

    func appendGroup(prefixes: [String], middlewares: [Middleware]) -> Router {
        let router = HTTPRouter(prefixes: self.prefixes + prefixes, middlewares: self.middlewares + middlewares)
        handlers.append(.router(router))
        return router
    }
}
