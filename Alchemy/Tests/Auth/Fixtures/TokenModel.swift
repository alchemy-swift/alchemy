import Alchemy
import Foundation

@Model
struct TokenModel: TokenAuthable {
    typealias Authorizes = AuthModel
    static let table = "token_models"

    var id: Int
    var value: UUID = UUID()
    var userId: Int

    @BelongsTo(from: "user_id") var user: AuthModel

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
