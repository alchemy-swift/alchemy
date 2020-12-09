import Alchemy

struct _20200119117000CreateUsers: Migration {
    func up(schema: Schema) {
        schema.create(table: "users") {
            $0.uuid("id").primary()
            $0.string("name").nullable(false)
            $0.string("email").nullable(false).unique()
            $0.uuid("mom").references("id", on: "users")
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "users")
    }
}

struct _20200219117000CreateTodos: Migration {
    func up(schema: Schema) {
        schema.create(table: "todos") {
            $0.increments("id").primary()
            $0.string("title").nullable(false)
            $0.bool("is_complete").default(val: false).nullable(false)
        }
        schema.create(table: "referrals") {
            $0.uuid("id").primary().default(expression: "uuid_generate_v4()")
            $0.string("code").nullable(false)
        }
        schema.create(table: "tokens") {
            $0.increments("id").primary()
            $0.uuid("user_id").references("id", on: "users")
            $0.string("code").nullable(false)
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "todos")
        schema.drop(table: "referrals")
        schema.drop(table: "tokens")
    }
}

struct _20200319117000RenameTodos: Migration {
    func up(schema: Schema) {
        schema.rename(table: "todos", to: "user_todos")
    }
    
    func down(schema: Schema) {
        schema.rename(table: "user_todos", to: "todos")
    }
}
