import NIO
import NIOHTTP1

/// The escape character for escaping path parameters.
///
/// e.g. /users/:userID/todos/:todoID would have path parameters named `userID` and `todoID`.
fileprivate let kRouterPathParameterEscape = ":"

/// This key is used for storing handlers in a dictionary for quick lookup.
private struct HTTPKey: Hashable {
    /// The method of the request.
    let method: HTTPMethod
    /// The path of the request, relative to the host.
    let path: String
}

/// An `Router` responds to HTTP requests from the client. Specifically, it takes an `Request`
/// and routes it to a handler that returns an `ResponseConvertible`.
public final class Router {
    private typealias RouterHandler = (Request) throws -> EventLoopFuture<Response>
    
    /// `Middleware` that will be applied to all requests of this router, regardless of whether they
    /// are able to be handled or not. Global middlewares intercept request in the order of this
    /// array, before any other middleware does.
    var globalMiddlewares: [Middleware] = []
    
    /// Current middleware of this router.
    var middlewares: [Middleware] = []
    
    /// A trie that holds all the handlers.
    private let trie = RouterTrieNode<HTTPKey, RouterHandler>()
    
    /// Creates a new router.
    init() {}
    
    /// Adds a handler to this router. A handler takes an `Request` and returns an
    /// `ResponseConvertible`.
    ///
    /// - Parameters:
    ///   - handler: the closure for handling a request matching the given method and path.
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
            var next: (Request) -> EventLoopFuture<Response> = { request in
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
    
    /// Handles a request. If the request has any dynamic path parameters in its URI,
    /// this will parse those out from the actual URI and set them on the `Request` before
    /// passing it to the handler closure.
    ///
    /// - Parameter request: The request this router will handle.
    /// - Throws: Any error encountered while handling the request.
    /// - Returns: A future containing the response of a handler or a `.notFound` response if there
    ///            was not a matching handler.
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

extension HTTPMethod: Hashable {
    // MARK: Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}

extension String {
    /// Indicates whether `self` matches a given `routablePath`. Any matching path parameters in the
    /// routablePath, denoted by their starting escape character `kRouterPathParameterEscape`, are
    /// returned as well.
    ///
    /// - Parameter routablePath: the routing path to test this string against.
    /// - Returns: a tuple with a `Bool` indicating whether the path was a match & any
    ///            `PathParameter`s that were extracted.
    fileprivate func matchAndParseParameters(
        routablePath: String
    ) -> (isMatch: Bool, pathParameters: [PathParameter]) {
        let pathParts = self.split(separator: "/")
        let routablePathParts = routablePath.split(separator: "/")
        var parameters: [PathParameter] = []
        
        guard pathParts.count == routablePathParts.count else {
            return (false, parameters)
        }
        
        for (index, pathPart) in pathParts.enumerated() {
            let routablePathPart = routablePathParts[index]
            
            // This path component is dynamic, don't check for equality.
            guard !routablePathPart.starts(with: kRouterPathParameterEscape) else {
                parameters.append(PathParameter(
                    parameter: String(routablePathPart.dropFirst(kRouterPathParameterEscape.count)),
                    stringValue: String(pathPart)
                ))
                continue
            }
            
            if pathPart != routablePathPart {
                return (false, parameters)
            }
        }
        
        return (true, parameters)
    }
}

/// A `Middleware` that is the combination of two `Middleware`s. On `intercept`, `first.intercept`
/// is run, followed by `second.intercept`.
private struct ChainedMiddleware: Middleware {
    /// The first middleware to run when this middleware intercepts a request.
    fileprivate let first: Middleware
    /// The second middleware to run when this middleware intercepts a request.
    fileprivate let second: Middleware
    
    // MARK: Middleware
    
    func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response> {
        try self.first.intercept(request) { request in
            catchError {
                try self.second.intercept(request, next: next)
            }
        }
    }
}
