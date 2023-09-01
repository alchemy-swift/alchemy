/// Something that handlers, middleware, and groups can be defined on.
public protocol Router {
    typealias Handler = (Request) async throws -> ResponseConvertible
    typealias ErrorHandler = (Request, Error) async throws -> ResponseConvertible

    /// Adds a Route to this Router.
    func appendRoute(matcher: RouteMatcher, options: RouteOptions, middlewares: [Middleware], handler: @escaping Handler)

    /// Adds some Middleware to this Router. The middleware will only run on
    /// reqeuests this router can handle.
    func appendMiddlewares(_ middlewares: [Middleware])

    /// Creates a group in this router. Requests added to this group will be
    /// prefixed by the given prefixes and run after the given middleware.
    func appendGroup(prefixes: [String], middlewares: [Middleware]) -> Router
}

/// Matches a Request against a Route. The match is a success if the request
/// path matches the variablized input path as well as an arbitrary
/// matching closure for more generic matching logic.
public struct RouteMatcher: Buildable {
    /// Any variables parsed from the path during matching.
    public var parameters: [Request.Parameter]

    private var pathTokens: [String]
    private let _match: (Request) -> Bool

    public init(path: String?, match: @escaping (Request) -> Bool) {
        self.parameters = []
        self.pathTokens = path.map { RouteMatcher.tokenize($0) } ?? []
        self._match = match
    }

    mutating func match(_ request: Request) -> Bool {
        matchPath(request.path) && _match(request)
    }

    mutating func prefixed(by prefixes: [String]) {
        pathTokens = prefixes.flatMap(RouteMatcher.tokenize) + pathTokens
    }

    private mutating func matchPath(_ path: String) -> Bool {
        parameters = []
        let parts = RouteMatcher.tokenize(path)
        for (index, token) in pathTokens.enumerated() {
            guard let part = parts[safe: index] else {
                return false
            }

            if token.hasPrefix(RouteMatcher.parameterEscape) {
                parameters.append(Request.Parameter(key: String(token.dropFirst()), value: part))
            } else if part != token {
                return false
            }
        }

        return true
    }

    private static func tokenize(_ path: String) -> [String] {
        path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
    }

    /// The character for indicating path parameters.
    ///
    /// e.g. /users/:userId/todos/:todoId would have path parameters named
    /// `userId` and `todoId`.
    private static let parameterEscape = ":"
}

public struct RouteOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let stream = RouteOptions(rawValue: 1 << 0)
}
