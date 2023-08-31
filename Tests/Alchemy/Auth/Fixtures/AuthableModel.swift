import Alchemy

struct AuthModel: Model, Codable, BasicAuthable {
    var id: PK<Int> = .new
    let email: String
    let password: String
    
    struct Migrate: Migration {
        func up(db: Database) async throws {
            try await db.createTable(AuthModel.table) {
                $0.increments("id")
                    .primary()
                $0.string("email")
                    .notNull()
                    .unique()
                $0.string("password")
                    .notNull()
            }
        }

        func down(db: Database) async throws {
            try await db.dropTable(AuthModel.table)
        }
    }
}

struct TokenModel: Model, Codable, TokenAuthable {
    typealias User = AuthModel

    var id: PK<Int> = .new
    var value = UUID()
    var userId: Int

    var user: BelongsTo<AuthModel> {
        belongsTo(from: "user_id")
    }

    struct Migrate: Migration {
        func up(db: Database) async throws {
            try await db.createTable(TokenModel.table) {
                $0.increments("id")
                    .primary()
                $0.uuid("value")
                    .notNull()
                $0.bigInt("user_id")
                    .notNull()
                    .references("id", on: "auth_models")
            }
        }

        func down(db: Database) async throws {
            try await db.dropTable(TokenModel.table)
        }
    }
}
