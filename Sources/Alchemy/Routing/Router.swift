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
    /// A route handler. Takes a request and returns a response.
    public typealias Handler = (Request) async throws -> ResponseConvertible
    
    /// A handler for returning a response after an error is
    /// encountered while initially handling the request.
    public typealias ErrorHandler = (Request, Error) async -> Response
    
    private typealias HTTPHandler = (Request) async -> Response

    /// The default response for when there is an error along the
    /// routing chain that does not conform to
    /// `ResponseConvertible`.
    var internalErrorHandler: ErrorHandler = { _, err in
        Log.error("[Server] encountered internal error: \(err).")
        return Response(
            status: .internalServerError,
            body: HTTPBody(text: HTTPResponseStatus.internalServerError.reasonPhrase)
        )
    }

    /// The response for when no handler is found for a Request.
    var notFoundHandler: Handler = { _ in
        Response(
            status: .notFound,
            body: HTTPBody(text: HTTPResponseStatus.notFound.reasonPhrase)
        )
    }
    
    /// `Middleware` that will intercept all requests through this
    /// router, before all other `Middleware` regardless of
    /// whether they are able to be handled.
    var globalMiddlewares: [Middleware] = []
    
    /// Current middleware of this router.
    var middlewares: [Middleware] = []
    
    /// Prefixes to prepend to any registered routes.
    var pathPrefixes: [String] = []
    
    /// A trie that holds all the handlers.
    private let trie = RouterTrieNode<HTTPMethod, HTTPHandler>()
    
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
    func add(handler: @escaping Handler, for method: HTTPMethod, path: String) {
        let pathPrefixes = pathPrefixes.map { $0.hasPrefix("/") ? String($0.dropFirst()) : $0 }
        let splitPath = pathPrefixes + path.tokenized
        let middlewareClosures = middlewares.reversed().map(Middleware.intercept)
        trie.insert(path: splitPath, storageKey: method) {
            var next = self.cleanHandler(handler)
            
            for middleware in middlewareClosures {
                let oldNext = next
                next = self.cleanHandler { try await middleware($0, oldNext) }
            }
            
            return await next($0)
        }
    }
    
    /// Handles a request. If the request has any dynamic path
    /// parameters in its URI, this will parse those out from
    /// the actual URI and set them on the `Request` before
    /// passing it to the handler closure.
    ///
    /// - Parameter request: The request this router will handle.
    /// - Returns: The response of a matching handler or a
    ///   `.notFound` response if there was not a
    ///   matching handler.
    func handle(request: Request) async -> Response {
        var handler = cleanHandler(notFoundHandler)

        // Find a matching handler
        if let match = trie.search(path: request.path.tokenized, storageKey: request.method) {
            request.pathParameters = match.parameters
            handler = match.value
        }
        
        // Apply global middlewares
        for middleware in globalMiddlewares.reversed() {
            let lastHandler = handler
            handler = cleanHandler {
                try await middleware.intercept($0, next: lastHandler)
            }
        }
        
        return await handler(request)
    }
    
    /// Converts a throwing, ResponseConvertible handler into a
    /// non-throwing Response handler.
    private func cleanHandler(_ handler: @escaping Handler) -> (Request) async -> Response {
        return { req in
            do {
                return try await handler(req).convert()
            } catch {
                if let error = error as? ResponseConvertible {
                    do {
                        return try await error.convert()
                    } catch {
                        return await self.internalErrorHandler(req, error)
                    }
                } else {
                    return await self.internalErrorHandler(req, error)
                }
            }
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
