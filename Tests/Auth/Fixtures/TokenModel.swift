import Alchemy

@Model
struct TokenModel: TokenAuthable {
    typealias Authorizes = AuthModel

    var id: Int
    var value: UUID = UUID()
    var userId: Int

    @BelongsTo var auth: AuthModel

    var user: BelongsTo<AuthModel> {
        $auth
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
