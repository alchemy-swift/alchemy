/// Represents the schema in a relational database.
extension Database {
    /// Create a table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: The name of the table to create.
    ///   - ifNotExists: If the query should silently not be run if
    ///     the table already exists. Defaults to `false`.
    ///   - builder: A closure for building the new table.
    public func create(table: String, ifNotExists: Bool = false, builder: (inout CreateTableBuilder) -> Void) async throws {
        var createBuilder = CreateTableBuilder(grammar: grammar)
        builder(&createBuilder)
        let createColumns = grammar.createTable(table, ifNotExists: ifNotExists, columns: createBuilder.createColumns)
        let createIndexes = grammar.createIndexes(on: table, indexes: createBuilder.createIndexes)
        for sql in [createColumns] + createIndexes {
            try await query(sql: sql)
        }
    }
    
    /// Alter an existing table with the supplied builder.
    ///
    /// - Parameters:
    ///   - table: The table to alter.
    ///   - builder: A closure passing a builder for defining what
    ///     should be altered.
    public func alter(table: String, builder: (inout AlterTableBuilder) -> Void) async throws {
        var alterBuilder = AlterTableBuilder(grammar: grammar)
        builder(&alterBuilder)
        let changes = grammar.alterTable(table, dropColumns: alterBuilder.dropColumns, addColumns: alterBuilder.createColumns)
        let renames = alterBuilder.renameColumns.map { grammar.renameColumn(on: table, column: $0.from, to: $0.to) }
        let dropIndexes = alterBuilder.dropIndexes.map { grammar.dropIndex(on: table, indexName: $0) }
        let createIndexes = grammar.createIndexes(on: table, indexes: alterBuilder.createIndexes)
        for sql in changes + renames + dropIndexes + createIndexes {
            try await query(sql: sql)
        }
    }
    
    /// Drop a table.
    ///
    /// - Parameter table: The table to drop.
    public func drop(table: String) async throws {
        try await query(sql: grammar.dropTable(table))
    }
    
    /// Rename a table.
    ///
    /// - Parameters:
    ///   - table: The table to rename.
    ///   - to: The new name for the table.
    public func rename(table: String, to: String) async throws {
        try await query(sql: grammar.renameTable(table, to: to))
    }

    /// Check if the database has a table with the given name.
    public func hasTable(_ table: String) async throws -> Bool {
        let sql = grammar.hasTable(table)
        return try await query(sql: sql).first?.fields.first?.value.bool() ?? false
    }
}
