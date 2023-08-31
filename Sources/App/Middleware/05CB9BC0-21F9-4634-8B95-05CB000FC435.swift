import Alchemy

struct 05CB9BC0-21F9-4634-8B95-05CB000FC435: Middleware {
    func intercept(_ request: Request, next: Next) async throws -> Response {
        // Write some code!
        return try await next(request)
    }
}