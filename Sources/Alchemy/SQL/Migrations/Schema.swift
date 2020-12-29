/// Represents the schema of a table in a relational database.
public class Schema {
    /// The grammar for how this schema should construct it's SQL statements.
    private let grammar: Grammar
    
    /// The statements to run to create a table matching this schema.
    var statements: [SQL] = []
    
    /// Initialize a schema with the given grammar.
    ///
    /// - Parameter grammar: the grammar by which this schema will construct its SQL statements.
    init(grammar: Grammar) {
        self.grammar = grammar
    }
    
    /// Create a table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: the name of the table to create.
    ///   - builder: a closure passing an object for building the new table.
    public func create(table: String, builder: (inout CreateTableBuilder) -> Void) {
        var createBuilder = CreateTableBuilder(grammar: self.grammar)
        builder(&createBuilder)
        
        let createColumns = self.grammar
            .compileCreate(table: table, columns: createBuilder.createColumns)
        let createIndexes = self.grammar
            .compileCreateIndexes(table: table, indexes: createBuilder.createIndexes)
        self.statements.append(contentsOf: [createColumns] + createIndexes)
    }
    
    /// Alter an existing table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: the table to alter.
    ///   - builder: a closure passing a builder for defining what should be altered.
    public func alter(table: String, builder: (inout AlterTableBuilder) -> Void) {
        var alterBuilder = AlterTableBuilder(grammar: self.grammar)
        builder(&alterBuilder)
        
        let changes = self.grammar.compileAlter(
            table: table,
            dropColumns: alterBuilder.dropColumns,
            addColumns: alterBuilder.createColumns
        )
        let renames = alterBuilder.renameColumns
            .map { self.grammar.compileRenameColumn(table: table, column: $0.from, to: $0.to) }
        let dropIndexes = alterBuilder.dropIndexes
            .map { self.grammar.compileDropIndex(table: table, indexName: $0) }
        let createIndexes = self.grammar
            .compileCreateIndexes(table: table, indexes: alterBuilder.createIndexes)
        self.statements.append(contentsOf: changes + renames + dropIndexes + createIndexes)
    }
    
    /// Drop a table.
    ///
    /// - Parameter table: the table to drop.
    public func drop(table: String) {
        self.statements.append(self.grammar.compileDrop(table: table))
    }
    
    /// Rename a table.
    ///
    /// - Parameters:
    ///   - table: the table to rename.
    ///   - to: the new name for the table.
    public func rename(table: String, to: String) {
        self.statements.append(self.grammar.compileRename(table: table, to: to))
    }
    
    /// Execute a raw SQL statement when running this migration schema.
    ///
    /// - Parameter sql: the raw SQL string to execute.
    public func raw(sql: String) {
        self.statements.append(SQL(sql, bindings: []))
    }
}
