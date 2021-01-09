import Alchemy

// Add / drop tables for `Todo`, `Tag`, and `TodoTag` models.
struct _20210107155107CreateTodos: Migration {
    func up(schema: Schema) {
        // Create a table backing `Todo`.
        schema.create(table: "todos") {
            $0.int("id").primary()
            $0.string("name").notNull()
            $0.bool("is_complete").notNull().default(val: false)
            $0.int("user_id").references("id", on: "users").notNull()
        }
        
        // Create a table backing `Tag`.
        schema.create(table: "tags") {
            $0.int("id").primary()
            $0.string("name").notNull()
            $0.int("color").notNull()
            $0.int("user_id").references("id", on: "users").notNull()
        }
        
        // Create a table backing `TodoTag`.
        schema.create(table: "todo_tags") {
            $0.int("id").primary()
            $0.int("todo_id").references("id", on: "todos").notNull()
            $0.int("tag_id").references("id", on: "tags").notNull()
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "todo_tags")
        schema.drop(table: "tags")
        schema.drop(table: "todos")
    }
}
