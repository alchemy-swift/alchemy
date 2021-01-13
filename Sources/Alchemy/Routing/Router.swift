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
public final class Router {
    /// A router handler. Takes a request and returns a future with a
    /// response.
    private typealias RouterHandler = (Request) throws -> EventLoopFuture<Response>
    
    /// `Middleware` that will intercept all requests through this
    /// router, before all other `Middleware` regardless of
    /// whether they are able to be handled.
    var globalMiddlewares: [Middleware] = []
    
    /// Current middleware of this router.
    var middlewares: [Middleware] = []
    
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
    func add(
        handler: @escaping (Request) throws -> ResponseConvertible,
        for method: HTTPMethod,
        path: String
    ) {
        let splitPath = path.split(separator: "/").map(String.init)
        let middlewareClosures = self.middlewares.reversed().map(Middleware.intercept)
        self.trie.insert(path: splitPath, storageKey: method) {
            var next = { request in
                catchError { try handler(request).convert() }
            }
            
            for middleware in middlewareClosures {
                let oldNext = next
                next = { request in
                    catchError { try middleware(request, oldNext) }
                }
            }
            
            return next($0)
        }
    }
    
    /// Handles a request. If the request has any dynamic path
    /// parameters in its URI, this will parse those out from
    /// the actual URI and set them on the `Request` before
    /// passing it to the handler closure.
    ///
    /// - Parameter request: The request this router will handle.
    /// - Throws: Any error encountered while handling the request.
    /// - Returns: A future containing the response of a handler or a
    ///   `.notFound` response if there was not a matching handler.
    func handle(request: Request) throws -> EventLoopFuture<Response> {
        let splitPath = request.path.split(separator: "/").map(String.init)
        guard let hit = self.trie.search(path: splitPath, storageKey: request.method) else {
            return try HTTPError(.notFound).convert()
        }
        
        request.pathParameters = hit.1
        
        return try hit.0(request)
    }
}

extension HTTPMethod: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}
