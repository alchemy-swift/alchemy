import NIO
import NIOHTTP1

fileprivate let kRouterPathParameterEscape = ":"

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
    typealias MiddlewareClosure = (HTTPRequest) -> EventLoopFuture<Input>
    
    private let basePath: String
    /// Middleware to apply to any requests before passing to a handler.
    private let middleware: MiddlewareClosure
    /// Child routers, erased to a closure.
    private var erasedChildren: [((HTTPRequest) -> EventLoopFuture<Output>?)] = []
    /// Handlers to route requests to.
    private var handlers: [HTTPKey: (Input) throws -> Output] = [:]

    init(basePath: String = "", middleware: @escaping MiddlewareClosure) {
        self.basePath = basePath
        self.middleware = middleware
    }
    
    private func childrenHandle(request: HTTPRequest) -> EventLoopFuture<Output>? {
        for child in self.erasedChildren {
            if let output = child(request) {
                return output
            }
        }
        
        return nil
    }
    
    func add(handler: @escaping (Input) throws -> Output, for method: HTTPMethod, path: String) {
        self.handlers[HTTPKey(fullPath: self.basePath + path, method: method)] = handler
    }
    
    func handle(request: HTTPRequest) -> EventLoopFuture<Output>? {
        for (key, value) in self.handlers {
            guard request.method == key.method else {
                continue
            }
            
            let matchResult = request.path.matchAndParseParameters(routablePath: key.fullPath)
            guard matchResult.isMatch else {
                continue
            }
            
            request.pathParameters = matchResult.parsedPathParameters
            
            return self.middleware(request)
                .flatMapThrowing { try value($0) }
        }
        
        return self.childrenHandle(request: request)
    }
    
    // A middleware that does something, but doesn't change the type
    public func middleware<M: Middleware>(_ middleware: M) -> Router<Input, Output> {
        let router = Router { req in
            middleware.intercept(req)
                .flatMap { self.middleware($0) }
        }
        self.erasedChildren.append(router.handle)
        return router
    }

    /// Update the path for subsequent requests in the router chain.
    public func path(_ path: String) -> Router<Input, Output> {
        let router = Router(basePath: self.basePath + path, middleware: self.middleware)
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
    fileprivate struct RouterMatchResult {
        let isMatch: Bool
        let parsedPathParameters: [PathParameter]
        
        static func `true`(_ params: [PathParameter]) -> RouterMatchResult {
            RouterMatchResult(isMatch: true, parsedPathParameters: params)
        }
        
        static func `false`(_ params: [PathParameter]) -> RouterMatchResult {
            RouterMatchResult(isMatch: false, parsedPathParameters: params)
        }
    }
    
    /// Indicates whether `self` matches a given `routablePath`. Any matching path parameters, denoted by
    /// their starting escape character `kRouterPathParameterEscape`, are returned as well.
    fileprivate func matchAndParseParameters(routablePath: String) -> RouterMatchResult {
        let pathParts = self.split(separator: "/")
        let routablePathParts = routablePath.split(separator: "/")
        var parameters: [PathParameter] = []
        
        guard pathParts.count == routablePathParts.count else {
            return .false(parameters)
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
                return .false(parameters)
            }
        }
        
        return .true(parameters)
    }
}
