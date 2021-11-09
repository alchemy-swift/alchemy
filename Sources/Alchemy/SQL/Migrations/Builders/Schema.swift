/// Represents the schema of a table in a relational database.
public class Schema {
    /// The grammar for how this schema should construct it's SQL
    /// statements.
    private let grammar: Grammar
    
    /// The statements to run to create a table matching this schema.
    var statements: [SQL] = []
    
    /// Initialize a schema with the given grammar.
    ///
    /// - Parameter grammar: The grammar by which this schema will
    ///   construct its SQL statements.
    init(grammar: Grammar) {
        self.grammar = grammar
    }
    
    /// Create a table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: The name of the table to create.
    ///   - ifNotExists: If the query should silently not be run if
    ///     the table already exists. Defaults to `false`.
    ///   - builder: A closure for building the new table.
    public func create(
        table: String,
        ifNotExists: Bool = false,
        builder: (inout CreateTableBuilder) -> Void
    ) {
        var createBuilder = CreateTableBuilder(grammar: self.grammar)
        builder(&createBuilder)
        
        let createColumns = self.grammar.compileCreate(
            table: table,
            ifNotExists: ifNotExists,
            columns: createBuilder.createColumns
        )
        let createIndexes = self.grammar
            .compileCreateIndexes(table: table, indexes: createBuilder.createIndexes)
        self.statements.append(contentsOf: [createColumns] + createIndexes)
    }
    
    /// Alter an existing table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: The table to alter.
    ///   - builder: A closure passing a builder for defining what
    ///     should be altered.
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
    /// - Parameter table: The table to drop.
    public func drop(table: String) {
        self.statements.append(self.grammar.compileDrop(table: table))
    }
    
    /// Rename a table.
    ///
    /// - Parameters:
    ///   - table: The table to rename.
    ///   - to: The new name for the table.
    public func rename(table: String, to: String) {
        self.statements.append(self.grammar.compileRename(table: table, to: to))
    }
    
    /// Execute a raw SQL statement when running this migration
    /// schema.
    ///
    /// - Parameter sql: The raw SQL string to execute.
    public func raw(sql: String) {
        self.statements.append(SQL(sql, bindings: []))
    }
}
