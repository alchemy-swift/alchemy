/// Responds to requests for an Application with affordances for global
/// middlewares, a custom not found handler, and a custom error handler.
public final class HTTPHandler: RequestHandler {
    private let maxUploadSize: Int?
    private let router: Middleware
    private var globalMiddlewares: [Middleware]
    private var notFoundHandler: (Request) async throws -> Response
    private var errorHandler: (Request, Error) async -> Response

    init(maxUploadSize: Int?, router: Middleware) {
        self.maxUploadSize = maxUploadSize
        self.router = router
        self.globalMiddlewares = []
        self.notFoundHandler = { _ in Response(status: .notFound, string: "404 Not Found") }
        self.errorHandler = HTTPHandler.defaultErrorHandler
    }

    public func handle(request: Request) async -> Response {
        do {
            if let maxUploadSize, let length = request.headers.contentLength, length > maxUploadSize {
                throw HTTPError(.payloadTooLarge)
            }

            let middlewares = globalMiddlewares + [router]
            return try await middlewares.handle(request, next: notFoundHandler)
        } catch {
            return await handleError(error, during: request)
        }
    }

    public func appendGlobalMiddlewares(_ middlewares: [Middleware]) {
        globalMiddlewares.append(contentsOf: middlewares)
    }

    public func setErrorHandler(_ handler: @escaping Router.ErrorHandler) {
        errorHandler = { request, initialError in
            do {
                return try await handler(request, initialError).response()
            } catch {
                return HTTPHandler.defaultErrorHandler(request: request, error: error)
            }
        }
    }

    public func setNotFoundHandler(_ handler: @escaping Router.Handler) {
        notFoundHandler = { try await handler($0).response() }
    }

    private func handleError(_ error: Error, during request: Request) async -> Response {
        guard let error = error as? ResponseConvertible else {
            return await errorHandler(request, error)
        }
        
        do {
            return try await error.response()
        } catch {
            return await errorHandler(request, error)
        }
    }

    private static func defaultErrorHandler(request: Request, error: Error) -> Response {
        Log.error("500 on \(request.method.rawValue) \(request.path): \(String(reflecting: error)).")
        return Response(status: .internalServerError, string: "500 Internal Server Error")
    }
}
