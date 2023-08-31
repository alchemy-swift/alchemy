import Alchemy

struct 5CBD3542-D65C-4AA9-AAB6-194237A02E71: Middleware {
    func intercept(_ request: Request, next: Next) async throws -> Response {
        // Write some code!
        return try await next(request)
    }
}