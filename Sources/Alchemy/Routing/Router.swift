import NIO
import NIOHTTP1

fileprivate let kRouterVariableEscape = ":"

private struct HTTPKey: Hashable {
    // The path of the request, relative to the host.
    let fullPath: String
    // The method of the request.
    let method: HTTPMethod
}

/// Router. Takes an `HTTPRequest` and routes it to a handler.
///
/// `Input` represents the type the router passes to a handler.
/// `Output` represents the type the router expects back from a handler.
public final class Router<Input, Output> {
    private let baseURI: String
    /// Middleware to apply to any requests before passing to a handler.
    private let middleware: (HTTPRequest) throws -> Input
    /// Child routers, erased to a closure.
    private var erasedChildren: [((HTTPRequest) throws -> Output?)] = []
    /// Handlers to route requests to.
    private var handlers: [HTTPKey: (Input) throws -> Output] = [:]

    init(baseURI: String = "", middleware: @escaping (HTTPRequest) throws -> Input) {
        self.baseURI = baseURI
        self.middleware = middleware
    }
    
    private func childrenHandle(request: HTTPRequest) throws -> Output? {
        for child in self.erasedChildren {
            if let output = try child(request) {
                return output
            }
        }
        
        return nil
    }
    
    func add(handler: @escaping (Input) throws -> Output, for method: HTTPMethod, path: String) {
        self.handlers[HTTPKey(fullPath: self.baseURI + path, method: method)] = handler
    }
    
    func handle(request: HTTPRequest) throws -> Output? {
        let key = HTTPKey(fullPath: request.head.uri, method: request.head.method)
//        self.handlers.contains(where: { key, value in
//            request
//        })
        guard let handler = self.handlers[key] else {
            return try self.childrenHandle(request: request)
        }
        
        return try handler(try self.middleware(request))
    }
    
    // A middleware that does something, but doesn't change the type
    public func middleware<M: Middleware>(_ middleware: M) -> Router<Input, Output> where M.Result == Void {
        let router = Router {
            try middleware.intercept($0)
            return try self.middleware($0)
        }
        
        self.erasedChildren.append(router.handle)
        return router
    }

    // A middleware that does something, then changes the type
    public func middleware<M: Middleware>(_ middleware: M) -> Router<(Input, M.Result), Output> {
        let router = Router<(Input, M.Result), Output> { request in
            (try self.middleware(request), try middleware.intercept(request))
        }
        
        self.erasedChildren.append(router.handle)
        return router
    }
    
    /// Update the path for subsequent requests in the router chain.
    public func path(_ path: String) -> Router<Input, Output> {
        let router = Router(baseURI: self.baseURI + path, middleware: self.middleware)
        self.erasedChildren.append(router.handle)
        return router
    }
}

extension HTTPMethod: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}

extension String {
    /// Does the given string match a routable URI? The
    fileprivate func matches(routablePath: String) -> Bool {
        let pathParts = self.split(separator: "/")
        let routablePathParts = routablePath.split(separator: "/")
        
        guard pathParts.count == routablePathParts.count else {
            return false
        }
        
        for (index, pathPart) in pathParts.enumerated() {
            let routablePathPart = routablePathParts[index]
            
            // This path component is a variable, don't check for equality.
            guard !routablePathPart.starts(with: kRouterVariableEscape) else { continue }
            
            if pathPart != routablePathPart {
                return false
            }
        }
        
        return true
    }
}
