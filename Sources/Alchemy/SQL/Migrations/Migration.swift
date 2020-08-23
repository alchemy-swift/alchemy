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
