struct Sample: Migration {
    func up(schema: Schema) {
        schema.rename(table: "todos", to: "user_todos")
        schema.create(table: "users") {
            $0.uuid("id").primary()
            $0.string("name").nullable(false)
            $0.string("email").nullable(false).unique().index()
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

protocol Migration {
    func up(schema: Schema)
    func down(schema: Schema)
}

struct Schema {
    var builders: [TableBuilder] = []
    
    func appending(builders: [TableBuilder]) -> Schema {
        Schema(builders: self.builders + builders)
    }
}

extension Schema {
    @discardableResult
    func create(table: String, builder: (CreateTableBuilder) -> Void) -> Schema {
        let createBuilder = CreateTableBuilder()
        builder(createBuilder)
        return self.appending(builders: [createBuilder])
    }
    
    @discardableResult
    func alter(table: String, builder: (AlterTableBuilder) -> Void) -> Schema {
        let alterBuilder = AlterTableBuilder()
        builder(alterBuilder)
        return self.appending(builders: [alterBuilder])
    }
    
    @discardableResult
    func drop(table: String) -> Schema {
        self.appending(builders: [DropTableBuilder()])
    }
    
    @discardableResult
    func rename(table: String, to: String) -> Schema {
        self.appending(builders: [RenameTableBuilder()])
    }
}

protocol TableBuilder {
    func sql() -> String
}

struct DropTableBuilder: TableBuilder {
    func sql() -> String { "" }
}

struct RenameTableBuilder: TableBuilder {
    func sql() -> String { "" }
}
