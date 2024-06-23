import Papyrus

// MARK: Alchemy

extension Router {
    public func register(
        method: String,
        path: String,
        action: @escaping (RouterRequest) async throws -> RouterResponse
    ) {
        let method = HTTPMethod(rawValue: method)
        on(method, at: path) { req in
            try await Request.$current
                .withValue(req) {
                    try await action(req.routerRequest())
                }
                .response()
        }
    }
}

extension Request {
    /// The current request. This can only be accessed inside of a route
    /// handler.
    @TaskLocal static var current: Request = {
        preconditionFailure("`Request.current` can only be accessed inside of a route handler task")
    }()
}

extension RouterResponse {
    fileprivate func response() -> Alchemy.Response {
        Response(
            status: .init(statusCode: status),
            headers: .init(headers.map { $0 }),
            body: body.map { .data($0) }
        )
    }
}

extension Alchemy.Request {
    fileprivate func routerRequest() -> RouterRequest {
        RouterRequest(
            url: url,
            method: method.rawValue,
            headers: Dictionary(
                headers.map { $0 },
                uniquingKeysWith: { first, _ in first }
            ),
            body: body?.data
        )
    }
}
