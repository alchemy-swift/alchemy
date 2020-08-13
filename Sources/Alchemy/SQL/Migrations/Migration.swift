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

public class Schema {
    private var grammar = MigrationGrammar()
    var statements: [SQL] = []
    
    func append(statements: [SQL]) {
        self.statements = self.statements + statements
    }
}

extension Schema {
    func create(table: String, builder: (inout CreateTableBuilder) -> Void) {
        var createBuilder = CreateTableBuilder()
        builder(&createBuilder)
        return self.append(statements: [
            self.grammar.compileCreate(table: table, columns: createBuilder.createColumns)
        ])
    }
    
    func alter(table: String, builder: (inout AlterTableBuilder) -> Void) {
        var alterBuilder = AlterTableBuilder(table: table)
        builder(&alterBuilder)
        let renames = alterBuilder.renameColumns.map {
            self.grammar.compileRenameColumn(table: table, column: $0.column, to: $0.to)
        }
        return self.append(statements: renames + [
            self.grammar.compileTableChange(table: table, dropColumns: alterBuilder.dropColumns,
                                            addColumns: alterBuilder.addColumns)
        ])
    }
    
    func drop(table: String) {
        self.append(statements: [self.grammar.compileDrop(table: table)])
    }
    
    func rename(table: String, to: String) {
        self.append(statements: [self.grammar.compileRename(table: table, to: to)])
    }
}
