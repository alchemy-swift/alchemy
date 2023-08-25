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
    private struct HandlerEntry {
        let options: RouteOptions
        let handler: (Request) async -> Response
    }
    
    /// A route handler. Takes a request and returns a response.
    public typealias Handler = (Request) async throws -> ResponseConvertible
    
    /// A handler for returning a response after an error is
    /// encountered while initially handling the request.
    public typealias ErrorHandler = (Request, Error) async throws -> ResponseConvertible

    /// The default response for when there is an error along the
    /// routing chain that does not conform to
    /// `ResponseConvertible`.
    var internalErrorHandler: ErrorHandler = Router.uncaughtErrorHandler
    
    /// The response for when no handler is found for a Request.
    var notFoundHandler: Handler = { _ in
        Response(status: .notFound)
            .withString(HTTPResponseStatus.notFound.reasonPhrase)
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
    private let trie = Trie<HandlerEntry>()

    /// Adds a handler to this router. A handler takes an `Request`
    /// and returns an `ResponseConvertible`.
    ///
    /// - Parameters:
    ///   - handler: The closure for handling a request matching the
    ///     given method and path.
    ///   - method: The method of a request this handler expects.
    ///   - path: The path of a requst this handler can handle.
    func add(handler: @escaping Handler, for method: HTTPMethod, path: String, options: RouteOptions) {
        let splitPath = pathPrefixes + path.tokenized(with: method)
        let middlewareClosures = middlewares.reversed().map(Middleware.handle)
        let entry = HandlerEntry(options: options) {
            var next = self.cleanHandler(handler)
            for middleware in middlewareClosures {
                let oldNext = next
                next = self.cleanHandler { try await middleware($0, oldNext) }
            }
            
            return await next($0)
        }
        
        trie.insert(path: splitPath, value: entry)
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
        var additionalMiddlewares = Array(globalMiddlewares.reversed())
        let app: Application? = Container.resolve()

        if let length = request.headers.contentLength, length > app?.configuration.maxUploadSize ?? .max {
            handler = cleanHandler { _ in throw HTTPError(.payloadTooLarge) }
        } else if let match = trie.search(path: request.path.tokenized(with: request.method)) {
            request.parameters = match.parameters
            handler = match.value.handler
            
            // Collate the request if streaming isn't specified.
            if !match.value.options.contains(.stream) {
                additionalMiddlewares.append(CollectionMiddleware())
            }
        }
        
        // Apply global middlewares
        for middleware in additionalMiddlewares {
            let lastHandler = handler
            handler = cleanHandler {
                try await middleware.handle($0, next: lastHandler)
            }
        }
        
        return await handler(request)
    }

    /// Converts a throwing, ResponseConvertible handler into a
    /// non-throwing Response handler.
    private func cleanHandler(_ handler: @escaping Handler) -> (Request) async -> Response {
        return { req in
            do {
                return try await handler(req).response()
            } catch {
                do {
                    if let error = error as? ResponseConvertible {
                        do {
                            return try await error.response()
                        } catch {
                            return try await self.internalErrorHandler(req, error).response()
                        }
                    }
                    
                    return try await self.internalErrorHandler(req, error).response()
                } catch {
                    return Router.uncaughtErrorHandler(req: req, error: error)
                }
            }
        }
    }
    
    /// The default error handler if an error is encountered while handling a
    /// request.
    private static func uncaughtErrorHandler(req: Request, error: Error) -> Response {
        Log.error("Encountered internal error: \(String(reflecting: error)).")
        return Response(status: .internalServerError)
            .withString(HTTPResponseStatus.internalServerError.reasonPhrase)
    }
}

extension String {
    fileprivate func tokenized(with method: HTTPMethod) -> [String] {
        split(separator: "/").map(String.init).filter { !$0.isEmpty } + [method.rawValue]
    }

    fileprivate var tokenized: [String] {
        split(separator: "/").map(String.init).filter { !$0.isEmpty }
    }
}

/*
 
 Router takes path.

 1. Looks up node @ path.
 2. Looks up all middleware for Method.
 3. Runs all middleware.

 */

protocol HandlerProtocol {
    func route(for request: Request) -> Route?
}

public struct Matcher {
    let method: HTTPMethod?
    let tokens: [String]

    init(method: HTTPMethod?, tokens: [String]) {
        self.method = method
        self.tokens = tokens
    }

    init(method: HTTPMethod?, string: String) {
        self.init(method: method, tokens: string.tokenized)
    }

    func match(_ request: Request) -> [Parameter]? {
        if let method {
            guard request.method == method else {
                return nil
            }
        }

        let reqParts = request.path.tokenized
        var parameters: [Parameter] = []
        for (index, part) in tokens.enumerated() {
            guard let reqPart = reqParts[safe: index] else {
                return nil
            }

            if reqPart.hasPrefix(kRouterPathParameterEscape) {
                let key = String(reqPart.dropFirst())
                parameters.append(Parameter(key: key, value: part))
            } else if reqPart != part {
                return nil
            }
        }

        return parameters
    }

    func with(prefixes: [String]) -> Matcher {
        Matcher(method: method, tokens: prefixes + tokens)
    }
}

final class HTTPRouter: RouteBuilder {
    let subrouter: Subrouter
    let globalMiddlewares: [Middleware]
    let notFoundHandler: (Request) async throws -> Response
    let errorHandler: (Request, Error) async throws -> Response
    let maxUploadSize: Int?

    init(maxUploadSize: Int?) {
        self.subrouter = Subrouter()
        self.globalMiddlewares = []
        self.notFoundHandler = { _ in Response(status: .notFound) }
        self.errorHandler = { _, _ in Response(status: .internalServerError) }
        self.maxUploadSize = maxUploadSize
    }
    
    func addHandler(matcher: Matcher, middlewares: [Middleware], options: RouteOptions, handler: @escaping (Request) async throws -> Response) {
        subrouter.addHandler(matcher: matcher, middlewares: middlewares, options: options, handler: handler)
    }

    func addMiddlewares(_ middlewares: [Middleware]) {
        subrouter.addMiddlewares(middlewares)
    }

    func addGroup(prefix: String, middlewares: [Middleware]) -> RouteBuilder {
        subrouter.addGroup(prefix: prefix, middlewares: middlewares)
    }

    func handle(request: Request) async -> Response {
        do {
            if let maxUploadSize, let length = request.headers.contentLength, length > maxUploadSize {
                throw HTTPError(.payloadTooLarge)
            }

            guard let route = subrouter.route(for: request) else {
                return try await notFoundHandler(request)
            }

            let additional = route.options.contains(.stream) ? [] : [CollectionMiddleware()]
            return try await send(request: request, through: additional + globalMiddlewares + route.middlewares, handler: route.handler)
        } catch {
            return await _errorHandler(request: request, error: error)
        }
    }

    private func _errorHandler(request: Request, error: Error) async -> Response {
        do {
            if let error = error as? ResponseConvertible {
                do {
                    return try await error.response()
                } catch {
                    return try await errorHandler(request, error)
                }
            } else {
                return try await errorHandler(request, error)
            }
        } catch {
            Log.error("Encountered internal error: \(String(reflecting: error)).")
            return Response(status: .internalServerError)
        }
    }

    private func send(request: Request, through middlewares: [Middleware], handler: (Request) async throws -> Response) async throws -> Response {
        guard let first = middlewares.first else {
            return try await handler(request)
        }

        return try await first.handle(request) {
            try await send(request: $0, through: Array(middlewares.dropFirst()), handler: handler)
        }
    }
}

final class Subrouter: HandlerProtocol, RouteBuilder {
    var prefixes: [String]
    var middlewares: [Middleware]
    var subrouters: [HandlerProtocol] = []

    init(prefixes: [String] = [], middlewares: [Middleware] = [], subrouters: [HandlerProtocol] = []) {
        self.prefixes = prefixes
        self.middlewares = middlewares
        self.subrouters = subrouters
    }

    func route(for request: Request) -> Route? {
        for subrouter in subrouters {
            if let route = subrouter.route(for: request) {
                return route.with(middleware: middlewares)
            }
        }

        return nil
    }

    func addHandler(matcher: Matcher, middlewares: [Middleware], options: RouteOptions, handler: @escaping (Request) async throws -> Response) {
        let route = Route(matcher: matcher.with(prefixes: prefixes), parameters: [], options: options, middlewares: middlewares, handler: handler)
        subrouters.append(route)
    }

    func addMiddlewares(_ middlewares: [Middleware]) {
        self.middlewares.append(contentsOf: middlewares)
    }

    func addGroup(prefix: String, middlewares: [Middleware]) -> RouteBuilder {
        let subrouter = Subrouter(prefixes: prefixes + prefix.tokenized, middlewares: middlewares)
        subrouters.append(subrouter)
        return subrouter
    }
}

struct Route: HandlerProtocol {
    let matcher: Matcher
    let parameters: [Parameter]
    let options: RouteOptions
    let middlewares: [Middleware]
    let handler: (Request) async throws -> Response

    func with(middleware: [Middleware]) -> Route {
        Route(matcher: matcher, parameters: parameters, options: options, middlewares: middlewares, handler: handler)
    }

    func with(parameters: [Parameter]) -> Route {
        Route(matcher: matcher, parameters: parameters, options: options, middlewares: middlewares, handler: handler)
    }

    func route(for request: Request) -> Route? {
        guard let params = matcher.match(request) else {
            return nil
        }

        return with(parameters: params)
    }
}

private struct CollectionMiddleware: Middleware {
    func handle(_ request: Request, next: Next) async throws -> Response {
        try await next(request.collect())
    }
}
