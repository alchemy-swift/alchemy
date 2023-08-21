import NIO
import NIOHTTP1
import Hummingbird

/// The escape character for escaping path parameters.
///
/// e.g. /users/:userID/todos/:todoID would have path parameters named
/// `userID` and `todoID`.
fileprivate let kRouterPathParameterEscape = ":"

/// An `Router` responds to HTTP requests from the client.
/// Specifically, it takes an `Request` and routes it to
/// a handler that returns an `ResponseConvertible`.
public final class Router {
    public struct RouteOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let stream = RouteOptions(rawValue: 1 << 0)
    }
    
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

    /// Internal hook for logging the result of each request.
    private var _didHandle: (Request, Response) -> Void = { _, _ in }

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
    func add(handler: @escaping Handler, for method: HTTPMethod, path: String, options: RouteOptions) {
        let splitPath = pathPrefixes + path.tokenized(with: method)
        let middlewareClosures = middlewares.reversed().map(Middleware.intercept)
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
        let hbApp: HBApplication? = Container.resolve()
        
        if let length = request.headers.contentLength, length > hbApp?.configuration.maxUploadSize ?? .max {
            handler = cleanHandler { _ in throw HTTPError(.payloadTooLarge) }
        } else if let match = trie.search(path: request.path.tokenized(with: request.method)) {
            request.parameters = match.parameters
            handler = match.value.handler
            
            // Collate the request if streaming isn't specified.
            if !match.value.options.contains(.stream) {
                additionalMiddlewares.append(AccumulateMiddleware())
            }
        }
        
        // Apply global middlewares
        for middleware in additionalMiddlewares {
            let lastHandler = handler
            handler = cleanHandler {
                try await middleware.intercept($0, next: lastHandler)
            }
        }
        
        let response = await handler(request)
        _didHandle(request, response)
        return response
    }

    func didHandle(_ hook: @escaping (Request, Response) -> Void) {
        let previous = _didHandle
        _didHandle = {
            previous($0, $1)
            hook($0, $1)
        }
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
}

private struct AccumulateMiddleware: Middleware {
    func intercept(_ request: Request, next: (Request) async throws -> Response) async throws -> Response {
        try await next(request.collect())
    }
}
