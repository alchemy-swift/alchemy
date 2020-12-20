import Foundation

/// A builder with useful functions for creating a table.
public class CreateTableBuilder {
    /// Any indexes that should be created.
    var createIndexes: [CreateIndex] = []
    
    /// All the columns to create on this table.
    var createColumns: [CreateColumn] {
        self.columnBuilders.map { $0.toCreate() }
    }
    
    /// References to the builders for all the columns on this table. Need to store these since they
    /// may be modified via column builder functions.
    private var columnBuilders: [ColumnBuilderErased] = []
    
    /// Add an index.
    ///
    /// It's name will be `<tableName>_<columnName1>_<columnName2>...` suffixed with `key` if it's
    /// unique or `idx` if not.
    ///
    /// - Parameters:
    ///   - columns: the names of the column(s) in this index.
    ///   - isUnique: whether this index will be unique.
    func addIndex(columns: [String], isUnique: Bool) {
        self.createIndexes.append(CreateIndex(columns: columns, isUnique: isUnique))
    }
    
    /// Adds an auto-incrementing `Int` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func increments(_ column: String) -> CreateColumnBuilder<Int> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "serial"))
    }
    
    /// Adds an `Int` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func int(_ column: String) -> CreateColumnBuilder<Int> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "int"))
    }
    
    /// Adds a `Double` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func double(_ column: String) -> CreateColumnBuilder<Double> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "float8"))
    }
    
    /// Adds an `String` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func string(_ column: String) -> CreateColumnBuilder<String> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "text"))
    }
    
    /// Adds a `UUID` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func uuid(_ column: String) -> CreateColumnBuilder<UUID> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "uuid"))
    }
    
    /// Adds a `Bool` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func bool(_ column: String) -> CreateColumnBuilder<Bool> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "bool"))
    }
    
    /// Adds a `Date` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func date(_ column: String) -> CreateColumnBuilder<Date> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "timestamptz"))
    }
    
    /// Adds a JSON column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func json(_ column: String) -> CreateColumnBuilder<SQLJSON> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "json"))
    }
    
    /// Adds a column builder to this table builder & returns it.
    ///
    /// - Parameter builder: the column builder to add to this table builder.
    /// - Returns: the passed in `builder`.
    private func appendAndReturn<T: Sequelizable>(
        builder: CreateColumnBuilder<T>
    ) -> CreateColumnBuilder<T> {
        self.columnBuilders.append(builder)
        return builder
    }
}

/// A type for keeping track of data associated with creating an index.
struct CreateIndex {
    /// The columns that make up this index.
    let columns: [String]
    
    /// Whether this index is unique or not.
    let isUnique: Bool
    
    /// Generate an SQL string for creating this index on a given table.
    ///
    /// - Parameter table: the name of the table this index will be created on.
    /// - Returns: an SQL string for creating this index on the given table.
    func toSQL(table: String) -> String {
        "CREATE \(self.isUnique ? "UNIQUE " : "")INDEX \(self.name(table: table)) ON \(table)"
    }
    
    /// Generate the name of this index given the table it will be created on.
    ///
    /// - Parameter table: the table this index will be created on.
    /// - Returns: the name of this index.
    private func name(table: String) -> String {
        ([table] + self.columns + [self.nameSuffix]).joined(separator: "_")
    }
    
    /// The suffix of the index name. "key" if it's a unique index, "idx" if not.
    private var nameSuffix: String {
        self.isUnique ? "key" : "idx"
    }
}

/// A type for keeping track of data associated with creating an column.
struct CreateColumn {
    /// The name.
    let column: String
    
    /// The type string.
    let type: String
    
    /// Any constraints.
    let constraints: [String]
    
    /// Convert this `CreateColumn` to a `String` for inserting into an SQL statement.
    ///
    /// - Returns: the SQL `String` describing this column.
    func toSQL() -> String {
        var baseSQL = "\(self.column) \(self.type)"
        if !self.constraints.isEmpty {
            baseSQL.append(" \(self.constraints.joined(separator: " "))")
        }
        return baseSQL
    }
}
