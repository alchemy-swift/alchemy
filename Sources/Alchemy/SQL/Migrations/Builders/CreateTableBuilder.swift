import Foundation

/// A builder with useful functions for creating a table.
public class CreateTableBuilder {
    /// The grammar with which this builder will compile SQL statements.
    let grammar: Grammar
    
    /// Any indexes that should be created.
    var createIndexes: [CreateIndex] = []
    
    /// All the columns to create on this table.
    var createColumns: [CreateColumn] {
        self.columnBuilders.map { $0.toCreate() }
    }
    
    /// Create a table builder with the given grammar.
    ///
    /// - Parameter grammar: the grammar with which this builder will compile SQL statements.
    init(grammar: Grammar) {
        self.grammar = grammar
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
    public func addIndex(columns: [String], isUnique: Bool) {
        self.createIndexes.append(CreateIndex(columns: columns, isUnique: isUnique))
    }
    
    /// Adds an auto-incrementing `Int` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func increments(_ column: String) -> CreateColumnBuilder<Int> {
        self.appendAndReturn(builder: CreateColumnBuilder(grammar: self.grammar, name: column, type: .increments))
    }
    
    /// Adds an `Int` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func int(_ column: String) -> CreateColumnBuilder<Int> {
        self.appendAndReturn(builder: CreateColumnBuilder(grammar: self.grammar, name: column, type: .int))
    }
    
    /// Adds a `Double` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func double(_ column: String) -> CreateColumnBuilder<Double> {
        self.appendAndReturn(builder: CreateColumnBuilder(grammar: self.grammar, name: column, type: .double))
    }
    
    /// Adds an `String` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Parameter length: the max length of this string. Defaults to `.limit(255)`.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func string(
        _ column: String,
        length: StringLength = .limit(255)
    ) -> CreateColumnBuilder<String> {
        self.appendAndReturn(builder: CreateColumnBuilder(grammar: self.grammar, name: column, type: .string(length)))
    }
    
    /// Adds a `UUID` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func uuid(_ column: String) -> CreateColumnBuilder<UUID> {
        let builder = CreateColumnBuilder<UUID>(grammar: self.grammar, name: column, type: .uuid)
        return self.appendAndReturn(builder: builder)
    }
    
    /// Adds a `Bool` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func bool(_ column: String) -> CreateColumnBuilder<Bool> {
        let builder = CreateColumnBuilder<Bool>(grammar: self.grammar, name: column, type: .bool)
        return self.appendAndReturn(builder: builder)
    }
    
    /// Adds a `Date` column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func date(_ column: String) -> CreateColumnBuilder<Date> {
        let builder = CreateColumnBuilder<Date>(grammar: self.grammar, name: column, type: .date)
        return self.appendAndReturn(builder: builder)
    }
    
    /// Adds a JSON column.
    ///
    /// - Parameter column: the name of the column to add.
    /// - Returns: a builder for adding modifiers to the column.
    @discardableResult public func json(_ column: String) -> CreateColumnBuilder<SQLJSON> {
        let builder = CreateColumnBuilder<SQLJSON>(grammar: self.grammar, name: column, type: .json)
        return self.appendAndReturn(builder: builder)
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
        let indexType = self.isUnique ? "UNIQUE INDEX" : "INDEX"
        let indexName = self.name(table: table)
        let indexColumns = "(\(self.columns.joined(separator: ", ")))"
        return "CREATE \(indexType) \(indexName) ON \(table) \(indexColumns)"
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
    let type: ColumnType
    
    /// Any constraints.
    let constraints: [String]
    
    /// Convert this `CreateColumn` to a `String` for inserting into an SQL statement.
    ///
    /// - Returns: the SQL `String` describing this column.
    func toSQL(with grammar: Grammar) -> String {
        var baseSQL = "\(self.column) \(grammar.typeString(for: self.type))"
        if !self.constraints.isEmpty {
            baseSQL.append(" \(self.constraints.joined(separator: " "))")
        }
        return baseSQL
    }
}
