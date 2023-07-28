/// Represents the schema of a table in a relational database.
public class Schema {
    /// The grammar for how this schema should construct it's SQL
    /// statements.
    private let grammar: SQLGrammar
    
    /// The statements to run to create a table matching this schema.
    var statements: [SQL] = []
    
    /// Initialize a schema with the given grammar.
    ///
    /// - Parameter grammar: The grammar by which this schema will
    ///   construct its SQL statements.
    init(grammar: SQLGrammar) {
        self.grammar = grammar
    }
    
    /// Create a table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: The name of the table to create.
    ///   - ifNotExists: If the query should silently not be run if
    ///     the table already exists. Defaults to `false`.
    ///   - builder: A closure for building the new table.
    public func create(table: String, ifNotExists: Bool = false, builder: (inout CreateTableBuilder) -> Void) {
        var createBuilder = CreateTableBuilder(grammar: grammar)
        builder(&createBuilder)
        let createColumns = grammar.compileCreateTable(table, ifNotExists: ifNotExists, columns: createBuilder.createColumns)
        let createIndexes = grammar.compileCreateIndexes(on: table, indexes: createBuilder.createIndexes)
        statements.append(contentsOf: [createColumns] + createIndexes)
    }
    
    /// Alter an existing table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: The table to alter.
    ///   - builder: A closure passing a builder for defining what
    ///     should be altered.
    public func alter(table: String, builder: (inout AlterTableBuilder) -> Void) {
        var alterBuilder = AlterTableBuilder(grammar: grammar)
        builder(&alterBuilder)
        let changes = grammar.compileAlterTable(table, dropColumns: alterBuilder.dropColumns, addColumns: alterBuilder.createColumns)
        let renames = alterBuilder.renameColumns.map { grammar.compileRenameColumn(on: table, column: $0.from, to: $0.to) }
        let dropIndexes = alterBuilder.dropIndexes.map { grammar.compileDropIndex(on: table, indexName: $0) }
        let createIndexes = grammar.compileCreateIndexes(on: table, indexes: alterBuilder.createIndexes)
        statements.append(contentsOf: changes + renames + dropIndexes + createIndexes)
    }
    
    /// Drop a table.
    ///
    /// - Parameter table: The table to drop.
    public func drop(table: String) {
        statements.append(grammar.compileDropTable(table))
    }
    
    /// Rename a table.
    ///
    /// - Parameters:
    ///   - table: The table to rename.
    ///   - to: The new name for the table.
    public func rename(table: String, to: String) {
        statements.append(grammar.compileRenameTable(table, to: to))
    }
    
    /// Execute a raw SQL statement when running this migration
    /// schema.
    ///
    /// - Parameter sql: The raw SQL string to execute.
    public func raw(sql: String, parameters: [SQLValue] = []) {
        statements.append(SQL(sql, parameters: parameters))
    }
}
