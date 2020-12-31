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

/// An `Router` responds to HTTP requests from the client. Specifically, it takes an `Request`
/// and routes it to a handler that returns an `HTTPResponseEncodable`.
public final class Router {
    /// `Middleware` that will be applied to all requests of this router, regardless of whether they
    /// are able to be handled or not. Global middlewares intercept request in the order of this
    /// array, before any other middleware does.
    public var globalMiddlewares: [Middleware] = []
    
    /// The path of this router, used for storing the path when the user calls `.path(...)`.
    private let basePath: String
    /// A middleware to apply to any requests before passing it to a handler.
    private let middleware: Middleware?
    /// Child routers. Ordered in the order that they should respond to a request.
    private var children: [Router] = []
    /// Handlers to route requests to.
    private var handlers: [HTTPKey: (Request) throws -> HTTPResponseEncodable] = [:]
    
    /// Creates a new router with an optional base path.
    ///
    /// - Parameters:
    ///   - basePath: any string that should be prepended to all handler URIs added to this router.
    ///               Defaults to nil.
    ///   - middleware: any middleware that should be run on a request routed by this router before
    ///                 handling. Defaults to `nil`.
    init(basePath: String? = nil, middleware: Middleware? = nil) {
        self.basePath = basePath ?? ""
        self.middleware = middleware
    }
    
    /// Returns a new router, a child of this one, that will apply the given middleware to any
    /// requests handled by it.
    ///
    /// - Parameter middleware: the middleware which will intercept all requests on this new router.
    /// - Returns: the new router with the middleware.
    public func middleware<M: Middleware>(_ middleware: M) -> Self {
        /// need to add my middleware
        var newRouter: Self
        if let first = self.middleware {
            newRouter = Self(middleware: ChainedMiddleware(first: first, second: middleware))
        } else {
            newRouter = Self(middleware: middleware)
        }
        self.children.append(newRouter)
        return newRouter
    }

    /// Returns a new router, a child of this one, that will prepend the given string to the URIs of
    /// all it's handlers.
    ///
    /// - Parameter path: the string to prepend to the URIs of all the new router's handlers.
    /// - Returns: the newly created `Router`, a child of `self`.
    public func path(_ path: String) -> Self {
        let newRouter = Self(basePath: self.basePath + path, middleware: self.middleware)
        self.children.append(newRouter)
        return newRouter
    }
    
    /// Adds a handler to this router. A handler takes an `Request` and returns an
    /// `HTTPResponseEncodable`.
    ///
    /// - Parameters:
    ///   - handler: the closure for handling a request matching the given method and path.
    ///   - method: the method of a request this handler expects.
    ///   - path: the path of a requst this handler can handle.
    func add(
        handler: @escaping (Request) throws -> HTTPResponseEncodable,
        for method: HTTPMethod,
        path: String
    ) {
        self.handlers[HTTPKey(fullPath: self.basePath + path, method: method)] = handler
    }
    
    /// Handles a request. If the request has any dynamic path parameters in its URI,
    /// this will parse those out from the actual URI and set them on the `Request` before
    /// passing it to the handler closure.
    ///
    /// - Parameter request: the request this router will handle.
    /// - Returns: a future containing the response of a handler or a `.notFound` response if there
    ///            was not a matching handler.
    func handle(request: Request) -> EventLoopFuture<Response> {
        guard let handlerFuture = self.handleIfAble(request: request) else {
            return .new(Response(status: .notFound, body: nil))
        }
        
        return handlerFuture
    }
    
    /// Handles a request if either this router or any of it's children are able to.
    ///
    /// - Parameter request: the request to handle.
    /// - Returns: a future with the response of the handler or nil if neither this router nor its
    ///            children are able to handle the request.
    private func handleIfAble(request: Request) -> EventLoopFuture<Response>? {
        for (key, value) in self.handlers {
            guard request.method == key.method else {
                continue
            }
            
            let (isMatch, parameters) = request.path
                .matchAndParseParameters(routablePath: key.fullPath)
            guard isMatch else {
                continue
            }
            
            request.pathParameters = parameters
            
            if let mw = self.middleware {
                return mw.intercept(request) { request in
                    catchError { try value(request).encode() }
                }
            } else {
                return catchError {
                    try value(request).encode()
                }
            }
        }
        
        for child in self.children {
            if let response = child.handleIfAble(request: request) {
                return response
            }
        }
        
        return nil
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
    
    func intercept(
        _ request: Request,
        next: @escaping Next
    ) -> EventLoopFuture<Response> {
        self.first.intercept(request) { request in
            self.second.intercept(request, next: next)
        }
    }
}
