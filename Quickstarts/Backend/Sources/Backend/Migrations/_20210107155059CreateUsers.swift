import Alchemy

// Add / drop tables for `User` and `UserToken` models.
struct _20210107155059CreateUsers: Migration {
    func up(schema: Schema) {
        // Create a table backing `User`.
        schema.create(table: "users") {
            $0.increments("id").primary()
            $0.string("name").notNull()
            $0.string("email").notNull().unique()
            $0.string("hashed_password").notNull()
        }
        
        // Create a table backing `UserToken`.
        schema.create(table: "user_tokens") {
            $0.increments("id").primary()
            $0.string("value").notNull()
            $0.date("created_at").notNull()
            $0.bigInt("user_id").unsigned().references("id", on: "users").notNull()
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "user_tokens")
        schema.drop(table: "users")
    }
}
