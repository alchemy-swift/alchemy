import AlchemyX

extension Application {
    @discardableResult
    public func useAlchemyX(db: Database = DB) -> Self {
        // 1. users table

        db.migrations.append(UserMigration())
        db.migrations.append(TokenMigration())

        // 2. users endpoint

        return use(AuthController())
    }
}

private struct AuthController: Controller, AuthAPI {
    func route(_ router: Router) {
        registerHandlers(on: router)
    }

    func signUp(email: String, password: String) async throws -> AuthResponse {
        let password = try await Hash.make(password)
        let user = try await User(email: email, password: password).insertReturn()
        let token = try await Token(userId: user.id()).insertReturn()
        return .init(token: token.value, user: user.dto)
    }

    func signIn(email: String, password: String) async throws -> AuthResponse {
        guard let user = try await User.firstWhere("email" == email) else {
            throw HTTPError(.notFound)
        }

        guard try await Hash.verify(password, hash: user.password) else {
            throw HTTPError(.unauthorized)
        }

        let token = try await Token(userId: user.id()).insertReturn()
        return .init(token: token.value, user: user.dto)
    }

    func signOut() async throws {
        try await token.delete()
    }

    func getUser() async throws -> AlchemyX.User {
        try user.dto
    }

    func updateUser(email: String?, phone: String?, password: String?) async throws -> AlchemyX.User {
        var user = try user
        if let email { user.email = email }
        if let phone { user.phone = phone }
        if let password { user.password = try await Hash.make(password) }
        return try await user.save().dto
    }
}

extension Controller {
    var req: Request { .current }
    fileprivate var user: User { get throws { try req.get() } }
    fileprivate var token: Token { get throws { try req.get() } }
}

struct Token: Model, Codable, TokenAuthable {
    typealias Authorizes = User

    var id: PK<UUID> = .new
    var value: String = UUID().uuidString
    let userId: UUID

    var user: BelongsTo<User> {
        belongsTo()
    }
}

struct User: Model, Codable {
    var id: PK<UUID> = .new
    var email: String
    var password: String
    var phone: String?

    var tokens: HasMany<Token> {
        hasMany()
    }

    var dto: AlchemyX.User {
        AlchemyX.User(
            id: id(),
            email: email,
            phone: phone
        )
    }
}

struct TokenMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("tokens") {
            $0.uuid("id").primary()
            $0.string("value").notNull()
            $0.uuid("user_id").references("id", on: "users").notNull()
        }
    }

    func down(db: Database) async throws {
        try await db.dropTable("tokens")
    }
}

struct UserMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("users") {
            $0.uuid("id").primary()
            $0.string("email").notNull()
            $0.string("password").notNull()
            $0.string("phone")
        }
    }
    
    func down(db: Database) async throws {
        try await db.dropTable("users")
    }
}
