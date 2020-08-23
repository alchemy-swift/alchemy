struct Sample: Migration {
    func up(schema: Schema) {
        schema.rename(table: "todos", to: "user_todos")
        schema.create(table: "users") {
            $0.uuid("id").primary()
            $0.string("name").nullable(false)
            $0.string("email").nullable(false).unique()
            $0.uuid("mom").references("id", on: "")
        }
        schema.drop(table: "referrals")
        schema.alter(table: "tokens") {
            $0.rename(column: "createdAt", to: "created_at")
            $0.bool("is_expired").default(val: false)
            $0.drop(column: "expiry_date")
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "users")
    }
}
