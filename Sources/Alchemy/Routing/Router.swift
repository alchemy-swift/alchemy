import NIO
import NIOHTTP1

/// The escape character for escaping path parameters.
///
/// e.g. /users/:userID/todos/:todoID would have path parameters named
/// `userID` and `todoID`.
fileprivate let kRouterPathParameterEscape = ":"

/// An `Router` responds to HTTP requests from the client.
/// Specifically, it takes an `Request` and routes it to
/// a handler that returns an `ResponseConvertible`.
public final class Router: HTTPRouter, Service {
    /// A router handler. Takes a request and returns a future with a
    /// response.
    private typealias RouterHandler = (Request) async throws -> Response

    /// The default response for when there is an error along the
    /// routing chain that does not conform to
    /// `ResponseConvertible`.
    public static var internalErrorResponse = Response(
        status: .internalServerError,
        body: HTTPBody(text: HTTPResponseStatus.internalServerError.reasonPhrase)
    )

    /// The response for when no handler is found for a Request.
    public static var notFoundResponse = Response(
        status: .notFound,
        body: HTTPBody(text: HTTPResponseStatus.notFound.reasonPhrase)
    )
    
    /// `Middleware` that will intercept all requests through this
    /// router, before all other `Middleware` regardless of
    /// whether they are able to be handled.
    var globalMiddlewares: [Middleware] = []
    
    /// Current middleware of this router.
    var middlewares: [Middleware] = []
    
    /// Prefixes to prepend to any registered routes.
    var pathPrefixes: [String] = []
    
    /// A trie that holds all the handlers.
    private let trie = RouterTrieNode<HTTPMethod, RouterHandler>()
    
    /// Creates a new router.
    init() {}
    
    /// Adds a handler to this router. A handler takes an `Request`
    /// and returns an `ResponseConvertible`.
    ///
    /// - Parameters:
    ///   - handler: The closure for handling a request matching the
    ///     given method and path.
    ///   - method: The method of a request this handler expects.
    ///   - path: The path of a requst this handler can handle.
    func add(handler: @escaping (Request) async throws -> ResponseConvertible, for method: HTTPMethod, path: String) {
        let pathPrefixes = pathPrefixes.map { $0.hasPrefix("/") ? String($0.dropFirst()) : $0 }
        let splitPath = pathPrefixes + path.tokenized
        let middlewareClosures = middlewares.reversed().map(Middleware.interceptConvertError)
        trie.insert(path: splitPath, storageKey: method) {
            var next = { (request: Request) async throws -> Response in
                do {
                    return try await handler(request).convert()
                } catch {
                    return await error.convertToResponse()
                }
            }
            
            for middleware in middlewareClosures {
                let oldNext = next
                next = { try await middleware($0, oldNext) }
            }
            
            return try await next($0)
        }
    }
    
    /// Handles a request. If the request has any dynamic path
    /// parameters in its URI, this will parse those out from
    /// the actual URI and set them on the `Request` before
    /// passing it to the handler closure.
    ///
    /// - Parameter request: The request this router will handle.
    /// - Returns: A future containing the response of a handler or a
    ///   `.notFound` response if there was not a matching handler.
    func handle(request: Request) async throws -> Response {
        var handler = notFoundHandler

        // Find a matching handler
        if let match = trie.search(path: request.path.tokenized, storageKey: request.method) {
            request.pathParameters = match.parameters
            handler = match.value
        }

        // Apply global middlewares
        for middleware in globalMiddlewares.reversed() {
            let lastHandler = handler
            handler = { try await middleware.interceptConvertError($0, next: lastHandler) }
        }

        return try await handler(request)
    }

    private func notFoundHandler(_ request: Request) async throws -> Response {
        Router.notFoundResponse
    }
}

private extension Middleware {
    func interceptConvertError(_ request: Request, next: @escaping Next) async throws -> Response {
        do {
            return try await intercept(request, next: next)
        } catch {
            return await error.convertToResponse()
        }
    }
}

private extension Error {
    func convertToResponse() async -> Response {
        func serverError() -> Response {
            Log.error("[Server] encountered internal error: \(self).")
            return Router.internalErrorResponse
        }

        do {
            if let error = self as? ResponseConvertible {
                return try await error.convert()
            } else {
                return serverError()
            }
        } catch {
            return serverError()
        }
    }
}

private extension String {
    var tokenized: [String] {
        return split(separator: "/").map(String.init)
    }
}

extension HTTPMethod: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}
