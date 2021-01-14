/// A protocol for automatically authenticating incoming requests
/// based on their `Authentication: Basic ...` header. When the
/// request is intercepted by the `BasicAuthMiddleware<T>`, it will
/// query the table of `T` in `Services.db` for a row that has a
/// matching username & validate the password. If the row exists
/// & the password matches, the type `T` will be `set` on the request.
///
/// ```swift
/// // Start with a Rune `Model`.
/// struct MyUser: BasicAuthable {
///     // Note that this defaults to "username" but you can override
///     // with a custom value.
///     static var usernameKeyString = "email"
///
///     var id: Int?
///     let email: String
///     let passwordHash: String
/// }
///
/// // Add the BasicAuthMiddleware in front of any endpoints that need
/// // auth.
/// app
///     // Will apply this auth middleware to all following requests.
///     .use(MyUser.basicAuthMiddleware())
///     .get("/login") { req in
///         // Middleware will have authed and set a user on the
///         // request, or returned an unauthorized response.
///         let authedUser = try req.get(User.self)
///     }
/// ```
public protocol BasicAuthable: Model {
    /// The name of the username row in the model. Defaults to
    /// "username", but can be overridden for custom rows.
    /// This row should be unique.
    static var usernameKeyString: String { get }
    
    /// The name of the hashed password row in the model. Defaults to
    /// "password_hash", but can be overridden for custom rows.
    static var passwordHashKeyString: String { get }
    
    /// Verifies a model's password hash given the password string
    /// from the `Authentication` header. Defaults to comparing
    /// `passwordHash` to a Bcrypt hash of the password. Can
    /// be overridden for custom password verification.
    ///
    /// - Parameters:
    ///   - password: The password from an Authentication header, to
    ///     be compared with the `passwordHash` of an existing model.
    ///   - passwordHash: The password value of the existing model.
    ///     Technically doesn't need to be a hashed value if
    ///     `passwordHashKeyString` points to an unhashed value, but
    ///     that wouldn't be very secure, would it?
    /// - Throws: Any error that might occur during the verification
    ///   process, by default a `CryptoError` if hashing fails.
    /// - Returns: a `Bool` indicating if `password` matched `passwordHash`.
    static func verify(password: String, passwordHash: String) throws -> Bool
}

extension BasicAuthable {
    public static var usernameKeyString: String { "username" }
    public static var passwordHashKeyString: String { "password_hash" }
    
    /// Default implementation of verification, compares a bcrypt hash
    /// of `password` to `passwordHash`.
    ///
    /// - Parameters:
    ///   - password: The raw password from the
    ///     `Authentication: Basic ...` header.
    ///   - passwordHash: The hashed password of the `BasicAuthable`
    ///     Rune model.
    /// - Throws: A `CryptoError` if hashing fails.
    /// - Returns: A `Bool` indicating if `password` matched
    ///   `passwordHash`.
    public static func verify(
        password: String,
        passwordHash: String
    ) throws -> Bool {
        try Bcrypt.verify(password, created: passwordHash)
    }
    
    /// A `Middleware` configured to validate the
    /// `Authentication: Basic ...` header of requests for a matching
    /// username/password in `Services.db`.
    ///
    /// - Returns: A `BasicAuthMiddleware<Self>` for authenticating
    ///   requests.
    public static func basicAuthMiddleware() -> BasicAuthMiddleware<Self> {
        BasicAuthMiddleware()
    }
}

/// A `Middleware` type configured to work with `BasicAuthable`. This
/// middleware will intercept requests and queries the table backing
/// `B` for a row matching the basic auth headers of the request. If a
/// matching row is found, that value will be associated with the
/// request. If there is no `Authentication: Basic ...` header, or the
/// basic auth values don't match a row in the database, an
/// `HTTPError(.unauthorized)` will be thrown.
public struct BasicAuthMiddleware<B: BasicAuthable>: Middleware {
    public func intercept(
        _ request: Request,
        next: @escaping Next
    ) -> EventLoopFuture<Response> {
        catchError {
            guard let basicAuth = request.basicAuth() else {
                throw HTTPError(.unauthorized)
            }
            
            return B.query()
                .where(B.usernameKeyString == basicAuth.username)
                .get(["\(B.tableName).*", B.passwordHashKeyString])
                .flatMapThrowing { rows -> B in
                    guard let firstRow = rows.first else {
                        throw HTTPError(.unauthorized)
                    }
                    
                    let passwordHash = try firstRow.getField(column: B.passwordHashKeyString).string()
                    
                    guard try B.verify(password: basicAuth.password, passwordHash: passwordHash) else {
                        throw HTTPError(.unauthorized)
                    }
                    
                    return try firstRow.decode(B.self)
                }
                .flatMap { next(request.set($0)) }
        }
    }
}
