public struct AnonymousMiddleware: Middleware {
    public let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func handle(_ request: Request, next: Next) async throws -> Response {
        try await handler(request, next)
    }
}
