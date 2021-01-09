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
    private let trie = RouterTrieNode<HTTPKey, RouterHandler>()
    
    /// Creates a new router.
    init() {}
    
    /// Adds a handler to this router. A handler takes an `Request`
    /// and returns an `ResponseConvertible`.
    ///
    /// - Parameters:
    ///   - handler: the closure for handling a request matching the
    ///   given method and path.
    ///   - method: the method of a request this handler expects.
    ///   - path: the path of a requst this handler can handle.
    func add(
        handler: @escaping (Request) throws -> ResponseConvertible,
        for method: HTTPMethod,
        path: String
    ) {
        let key = HTTPKey(method: method, path: path)
        let splitPath = path.split(separator: "/").map(String.init)
        self.trie.insert(path: splitPath, storageKey: key) {
            var next = { request in
                catchError { try handler(request).convert() }
            }
            
            for middleware in self.middlewares.reversed() {
                next = { request in
                    catchError { try middleware.intercept(request, next: next) }
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
    /// `.notFound` response if there was not a matching handler.
    func handle(request: Request) throws -> EventLoopFuture<Response> {
        let key = HTTPKey(method: request.method, path: request.path)
        let splitPath = request.path.split(separator: "/").map(String.init)
        guard let hit = self.trie.search(path: splitPath, storageKey: key) else {
            return try HTTPError(.notFound).convert()
        }
        
        request.pathParameters = hit.1
        
        return try hit.0(request)
    }
}

/// A key used for storing handlers in a dictionary for quick lookup.
private struct HTTPKey: Hashable {
    /// The method of the request.
    let method: HTTPMethod
    /// The path of the request, relative to the host.
    let path: String
}

extension HTTPMethod: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}
