import Papyrus

// MARK: Alchemy

extension Router {
    public func register(
        method: String,
        path: String,
        action: @escaping (RouterRequest) async throws -> RouterResponse
    ) {
        let method = HTTPRequest.Method(rawValue: method)!
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
        Alchemy.Response(
            status: .init(integerLiteral: status),
            headers: fields,
            body: body.map { .data($0) }
        )
    }

    var fields: HTTPFields {
        var fields = HTTPFields()
        for (key, value) in headers {
            guard let name = HTTPField.Name(key) else {
                continue
            }

            fields[name] = value
        }

        return fields
    }
}

extension Alchemy.Request {
    fileprivate func routerRequest() -> RouterRequest {
        RouterRequest(
            url: url,
            method: method.rawValue,
            headers: Dictionary(
                headers.map { ($0.name.rawName, $0.value) },
                uniquingKeysWith: { first, _ in first }
            ),
            body: body?.data
        )
    }
}
