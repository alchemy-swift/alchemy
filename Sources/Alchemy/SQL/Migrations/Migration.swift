public protocol Migration {
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
    public func create(table: String, builder: (inout CreateTableBuilder) -> Void) {
        var createBuilder = CreateTableBuilder()
        builder(&createBuilder)
        
        let createColumns = self.grammar.compileCreate(table: table, columns: createBuilder.createColumns)
        let createIndexes = self.grammar.compileCreateIndexes(table: table, indexes: createBuilder.createIndexes)
        self.append(statements: [createColumns] + createIndexes)
    }
    
    public func alter(table: String, builder: (inout AlterTableBuilder) -> Void) {
        var alterBuilder = AlterTableBuilder(table: table)
        builder(&alterBuilder)
        
        let changes = self.grammar.compileAlter(table: table, dropColumns: alterBuilder.dropColumns,
                                                      addColumns: alterBuilder.createColumns)
        let renames = alterBuilder.renameColumns
            .map { self.grammar.compileRenameColumn(table: table, column: $0.column, to: $0.to) }
        let dropIndexes = alterBuilder.dropIndexes
            .map { self.grammar.compileDropIndex(table: table, indexName: $0) }
        let createIndexes = self.grammar
            .compileCreateIndexes(table: table, indexes: alterBuilder.createIndexes)
        self.append(statements: changes + renames + dropIndexes + createIndexes)
    }
    
    public func drop(table: String) {
        self.append(statements: [self.grammar.compileDrop(table: table)])
    }
    
    public func rename(table: String, to: String) {
        self.append(statements: [self.grammar.compileRename(table: table, to: to)])
    }
    
    public func raw(sql: String) {
        self.append(statements: [SQL(sql, bindings: [])])
    }
}
