/// A protocol for automatically authenticating incoming requests
/// based on their `Authentication: Basic ...` header. When the
/// request is intercepted by the `BasicAuthMiddleware<T>`, it will
/// query the table of `T` in `Database.default` for a row that has a
/// matching username & validate the password. If the row exists
/// & the password matches, the type `T` will be `set` on the request.
///
/// ```swift
/// // Start with a Rune `Model`.
/// struct MyUser: BasicAuthable {
///     // Note that this defaults to "email" but you can override
///     // with a custom value.
///     static var usernameKeyString = "username"
///
///     var id: Int?
///     let email: String
///     let password: String
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
    /// "email", but can be overridden for custom rows.
    /// This row should be unique.
    static var usernameKeyString: String { get }
    
    /// The name of the password row in the model. Defaults to
    /// "password", but can be overridden for custom rows.
    static var passwordKeyString: String { get }
    
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
    static func verify(password: String, passwordHash: String) async throws -> Bool
}

extension BasicAuthable {
    public static var usernameKeyString: String { "email" }
    public static var passwordKeyString: String { "password" }
    
    /// Default implementation of verification, compares a bcrypt hash
    /// of `password` to `passwordHash`.
    ///
    /// - Parameters:
    ///   - password: The raw password from the
    ///     `Authentication: Basic ...` header.
    ///   - passwordHash: The hashed password of the `BasicAuthable`
    ///     Rune model.
    /// - Returns: A `Bool` indicating if `password` matched
    ///   `passwordHash`.
    public static func verify(password: String, passwordHash: String) async throws -> Bool {
        try await Hash.verify(password, hash: passwordHash)
    }
    
    /// A `Middleware` configured to validate the
    /// `Authentication: Basic ...` header of requests for a matching
    /// username/password in `Database.default`.
    ///
    /// - Returns: A `BasicAuthMiddleware<Self>` for authenticating
    ///   requests.
    public static func basicAuthMiddleware(db: Database = DB) -> BasicAuthMiddleware<Self> {
        BasicAuthMiddleware(db: db)
    }
    
    /// Authenticates this model with a username and password.
    ///
    /// - Parameters:
    ///   - username: The username to authenticate with.
    ///   - password: The password to authenticate with.
    ///   - error: An error to throw if the username password combo
    ///     doesn't have a match.
    /// - Returns: A the authenticated `BasicAuthable`, if there was
    ///   one. Throws `error` if the model is not found, or the
    ///   password doesn't match.
    public static func authenticate(
        db: Database = DB,
        username: String,
        password: String,
        else error: Error = HTTPError(.unauthorized)
    ) async throws -> Self {
        let rows = try await db
            .table(Self.table)
            .where(usernameKeyString == username)
            .select("\(table).*", passwordKeyString)
            .get()

        guard let firstRow = rows.first else {
            throw error
        }
        
        guard let passwordHash = try firstRow[passwordKeyString]?.string() else {
            throw DatabaseError("Missing column \(passwordKeyString) on row of type \(name(of: Self.self))")
        }
        
        guard try await verify(password: password, passwordHash: passwordHash) else {
            throw error
        }
        
        return try firstRow.decodeModel(Self.self)
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
    private let db: Database

    public init(db: Database = DB) {
        self.db = db
    }

    public func handle(_ request: Request, next: Next) async throws -> Response {
        guard let basicAuth = request.basicAuth() else {
            throw HTTPError(.unauthorized)
        }
        
        let model = try await B.authenticate(db: db, username: basicAuth.username, password: basicAuth.password)
        return try await next(request.set(model))
    }
}
