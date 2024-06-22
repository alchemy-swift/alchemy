/// A protocol for automatically authenticating incoming requests
/// based on their `Authentication: Bearer ...` header. When the
/// request is intercepted by a related `TokenAuthMiddleware<T>`, it
/// will query the table of `T` in `Database.default` for a row that has a
/// matching token value. If the exists, the correlating `User` type
/// will be queried and `set` on the request.
///
/// ```swift
/// // Start with a Rune `Model`.
/// struct Token: TokenAuthable {
///     // `KeyPath` to the relation of the `User`.
///     static var userKey = \Token.$user
///
///     var id: Int?
///     let value: String
///
///     @BelongsTo
///     var user: User
/// }
///
/// // Add the TokenAuthMiddleware in front of any endpoints that need
/// // auth.
/// app
///     // Will apply this auth middleware to all following requests.
///     .use(MyToken.tokenAuthMiddleware())
///     .get("/todos") { req in
///         // Middleware will have authed and set a user on the
///         // request, or returned an unauthorized response.
///         let authedUser = try req.get(User.self)
///
///         ...
///     }
/// ```
public protocol TokenAuthable: Model {
    /// The type associated with this token, i.e. a token will always
    /// be associated with some sort of `User` type. When the token
    /// is successfully authorized, the corresponding model of
    /// this type will be pulled from the database and
    /// associated with the request.
    associatedtype Authorizes: Model
    associatedtype AuthorizesRelation: Relationship<Self, Authorizes>

    /// The user in question.
    var user: AuthorizesRelation { get }

    /// The name of the row that stores the token's value. Defaults to
    /// `"value"`.
    static var valueKeyString: String { get }
}

extension TokenAuthable {
    public static var valueKeyString: String { "value" }
    
    /// A `Middleware` configured to validate the
    /// `Authentication: Bearer ...` header of requests for a matching
    /// token in `Database.default`.
    ///
    /// - Returns: A `TokenAuthMiddleware<Self>` for authenticating
    ///   requests.
    public static func tokenAuthMiddleware() -> TokenAuthMiddleware<Self> {
        TokenAuthMiddleware()
    }
}

/// A `Middleware` type configured to work with `TokenAuthable`. This
/// middleware will handle requests and queries the table backing
/// `T` for a row matching the token auth headers of the request.
/// If a matching row is found, that value will be associated
/// with the request. If there is no `Authentication: Token ...`
/// header, or the token value isn't valid, an
/// `HTTPError(.unauthorized)` will be thrown.
public struct TokenAuthMiddleware<T: TokenAuthable>: Middleware {
    public func handle(_ request: Request, next: Next) async throws -> Response {
        guard let bearerAuth = request.bearerAuth() else {
            throw HTTPError(.unauthorized)
        }
        
        guard let model = try await T
            .where(T.valueKeyString == bearerAuth.token)
            .with(\.user)
            .first()
        else {
            throw HTTPError(.unauthorized)
        }

        return try await next(
            request
                .set(model)
                .set(model.user())
        )
    }
}
