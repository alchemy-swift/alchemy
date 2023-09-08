import Alchemy

struct TokenModel: Model, Codable, TokenAuthable {
    typealias Authorizes = AuthModel

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
