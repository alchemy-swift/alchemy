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
