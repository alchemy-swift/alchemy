import Alchemy

struct _20200119117000CreateUsers: Migration {
    func up(schema: Schema) {
        schema.create(table: "users") {
            $0.uuid("id").primary()
            $0.string("name").notNull()
            $0.string("email").notNull().unique()
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
            $0.string("title").notNull()
            $0.bool("is_complete").default(val: false).notNull()
        }
        schema.create(table: "referrals") {
            $0.uuid("id").primary().default(expression: "uuid_generate_v4()")
            $0.string("code").notNull()
        }
        schema.create(table: "tokens") {
            $0.increments("id").primary()
            $0.uuid("user_id").references("id", on: "users")
            $0.string("code").notNull()
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

struct _20201229164212CreatePets: Migration {
    func up(schema: Schema) {
        schema.create(table: "owners") {
            $0.increments("id").primary()
            $0.string("name").notNull()
        }
        
        schema.create(table: "vaccines") {
            $0.increments("id").primary()
            $0.string("name").notNull()
        }
        
        schema.create(table: "pets") {
            $0.increments("id").primary()
            $0.string("name").notNull()
            $0.int("owner_id").references("id", on: "owners")
        }
        
        schema.create(table: "licenses") {
            $0.increments("id").primary()
            $0.string("code").notNull()
            $0.int("owner_id").references("id", on: "owners")
        }
        
        schema.create(table: "pet_vaccines") {
            $0.increments("id").primary()
            $0.int("pet_id").references("id", on: "pets")
            $0.int("vaccine_id").references("id", on: "vaccines")
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "owners")
        schema.drop(table: "vaccines")
        schema.drop(table: "pets")
        schema.drop(table: "licenses")
        schema.drop(table: "pet_vaccines")
    }
}
