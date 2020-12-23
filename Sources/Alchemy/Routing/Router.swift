import NIO
import NIOHTTP1

/// The escape character for escaping path parameters.
///
/// e.g. /users/:userID/todos/:todoID would have path parameters named `userID` and `todoID`.
fileprivate let kRouterPathParameterEscape = ":"

/// This key is used for storing handlers in a dictionary for quick lookup.
private struct HTTPKey: Hashable {
    /// The path of the request, relative to the host.
    let fullPath: String
    /// The method of the request.
    let method: HTTPMethod
}

/// An `Router` responds to HTTP requests from the client. Specifically, it takes an `HTTPRequest`
/// and routes it to a handler that returns an `HTTPResponseEncodable`.
public final class Router {
    /// Represents a middleware closure for this router.
    typealias MiddlewareClosure = (HTTPRequest) -> EventLoopFuture<HTTPRequest>
    
    /// The path of this router, used for storing the path when the user calls `.path(...)`.
    private let basePath: String
    
    /// Middleware to apply to any requests before passing to a handler.
    private let middleware: MiddlewareClosure
    
    /// Child routers, erased to a closure. Ordered in the order that they should respond to a
    /// request.
    private var erasedChildren: [((HTTPRequest) -> EventLoopFuture<HTTPResponseEncodable>?)] = []
    
    /// Handlers to route requests to.
    private var handlers: [HTTPKey: (HTTPRequest) throws -> HTTPResponseEncodable] = [:]
    
    /// Creates a new router with an optional base path.
    ///
    /// - Parameters:
    ///   - basePath: any string that should be prepended to all handler URIs added to this router.
    ///               Defaults to nil.
    ///   - middleware: any middleware closure that should be run on a request routed by this router
    ///                 before handling. Defaults to nil.
    init(basePath: String? = nil, middleware: MiddlewareClosure? = nil) {
        self.basePath = basePath ?? ""
        self.middleware = middleware ?? { .new($0) }
    }
    
    /// Attempts to handle a request via child handlers. Returns nil if no child handler can handle
    /// the request.
    ///
    /// - Parameter request: the request to pass off to this router's child handlers.
    /// - Returns: a response future if a child was able to handle the reqeust, nil if not.
    private func childrenHandle(request: HTTPRequest) -> EventLoopFuture<HTTPResponseEncodable>? {
        for child in self.erasedChildren {
            if let output = child(request) {
                return output
            }
        }
        
        return nil
    }
    
    /// Adds a handler to this router. A handler takes an `HTTPRequest` and returns an
    /// `HTTPResponseEncodable`.
    ///
    /// - Parameters:
    ///   - handler: the closure for handling a request matching the given method and path.
    ///   - method: the method of a request this handler expects.
    ///   - path: the path of a requst this handler can handle.
    func add(handler: @escaping (HTTPRequest) throws -> HTTPResponseEncodable, for method: HTTPMethod, path: String) {
        self.handlers[HTTPKey(fullPath: self.basePath + path, method: method)] = handler
    }
    
    /// Attempts to handle a request. If the request has any dynamic path parameters in its URI,
    /// this will parse those out from the actual URI and set them on the `HTTPRequest` before
    /// passing it to the handler closure.
    ///
    /// - Parameter request: the request this router will attempt to handle.
    /// - Returns: a future containing the response of the handler if there was a matching handler.
    ///            nil if there were no matching handlers.
    func handle(request: HTTPRequest) -> EventLoopFuture<HTTPResponseEncodable>? {
        for (key, value) in self.handlers {
            guard request.method == key.method else {
                continue
            }
            
            let (isMatch, parameters) = request.path.matchAndParseParameters(routablePath: key.fullPath)
            guard isMatch else {
                continue
            }
            
            request.pathParameters = parameters
            
            return self.middleware(request)
                .flatMapThrowing { try value($0) }
        }
        
        return self.childrenHandle(request: request)
    }
    
    /// Returns a new router, a child of this one, that will apply the given middleware to any
    /// requests handled by it.
    ///
    /// - Parameter middleware: the middleware which will intercept all requests on this new router.
    /// - Returns: the new router with the middleware.
    public func middleware<M: Middleware>(_ middleware: M) -> Self {
        let router = Self { req in
            middleware.intercept(req)
                .flatMap { self.middleware($0) }
        }
        self.erasedChildren.append(router.handle)
        return router
    }

    /// Returns a new router, a child of this one, that will prepend the given string to the URIs of
    /// all it's handlers.
    ///
    /// - Parameter path: the string to prepend to the URIs of all the new router's handlers.
    /// - Returns: the newly created `Router`, a child of `self`.
    public func path(_ path: String) -> Self {
        let router = Self(basePath: self.basePath + path, middleware: self.middleware)
        self.erasedChildren.append(router.handle)
        return router
    }
    
    /// Middleware that will be applied to all requests of the application, regardless of whether
    /// they are able to be handled or not. Global middlewares intercept request in the order of
    /// this array, before any other middleware does.
    public static var globalMiddlewares: [Middleware] = []
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
