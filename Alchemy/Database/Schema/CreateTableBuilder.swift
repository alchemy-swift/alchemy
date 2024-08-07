import Foundation

/// A builder with useful functions for creating a table.
public class CreateTableBuilder {
    /// The grammar with which this builder will compile SQL
    /// statements.
    let grammar: SQLGrammar

    /// Any indexes that should be created.
    var createIndexes: [CreateIndex] = []
    
    /// All the columns to create on this table.
    var createColumns: [CreateColumn] {
        columnBuilders.map { $0.toCreate() }
    }
    
    /// References to the builders for all the columns on this table.
    /// Need to store these since they may be modified via column
    /// builder functions.
    private var columnBuilders: [ColumnBuilderErased] = []
    
    /// Create a table builder with the given grammar.
    ///
    /// - Parameter grammar: The grammar with which this builder will
    ///   compile SQL statements.
    init(grammar: SQLGrammar) {
        self.grammar = grammar
    }

    /// Add an index.
    ///
    /// It's name will be `<tableName>_<columnName1>_<columnName2>...`
    /// suffixed with `key` if it's unique or `idx` if not.
    ///
    /// - Parameters:
    ///   - columns: The names of the column(s) in this index.
    ///   - isUnique: Whether this index will be unique.
    public func addIndex(columns: [String], isUnique: Bool) {
        createIndexes.append(CreateIndex(columns: columns, isUnique: isUnique))
    }

    /// Adds an auto-incrementing `Int` column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func increments(_ column: String) -> CreateColumnBuilder<Int> {
        appendAndReturn(builder: CreateColumnBuilder(grammar: grammar, name: column, type: .increments))
    }

    /// Adds an `Int` column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func int(_ column: String) -> CreateColumnBuilder<Int> {
        appendAndReturn(builder: CreateColumnBuilder(grammar: grammar, name: column, type: .int))
    }

    /// Adds a big int column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func bigInt(_ column: String) -> CreateColumnBuilder<Int> {
        appendAndReturn(builder: CreateColumnBuilder(grammar: grammar, name: column, type: .bigInt))
    }

    /// Adds a `Double` column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func double(_ column: String) -> CreateColumnBuilder<Double> {
        appendAndReturn(builder: CreateColumnBuilder(grammar: grammar, name: column, type: .double))
    }

    /// Adds an `String` column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Parameter length: The max length of this string. Defaults to
    ///   `.limit(255)`.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func string(
        _ column: String,
        length: ColumnType.StringLength = .limit(255)
    ) -> CreateColumnBuilder<String> {
        appendAndReturn(builder: CreateColumnBuilder(grammar: grammar, name: column, type: .string(length)))
    }

    /// Adds a `UUID` column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func uuid(_ column: String) -> CreateColumnBuilder<UUID> {
        let builder = CreateColumnBuilder<UUID>(grammar: grammar, name: column, type: .uuid)
        return appendAndReturn(builder: builder)
    }

    /// Adds a `Bool` column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func bool(_ column: String) -> CreateColumnBuilder<Bool> {
        let builder = CreateColumnBuilder<Bool>(grammar: grammar, name: column, type: .bool)
        return appendAndReturn(builder: builder)
    }

    /// Adds a `Date` column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func date(_ column: String) -> CreateColumnBuilder<Date> {
        let builder = CreateColumnBuilder<Date>(grammar: grammar, name: column, type: .date)
        return appendAndReturn(builder: builder)
    }

    /// Adds a JSON column.
    ///
    /// - Parameter column: The name of the column to add.
    /// - Returns: A builder for adding modifiers to the column.
    @discardableResult public func json(_ column: String) -> CreateColumnBuilder<SQLJSON> {
        let builder = CreateColumnBuilder<SQLJSON>(grammar: grammar, name: column, type: .json)
        return appendAndReturn(builder: builder)
    }

    /// Adds `created_at` and `updated_at` columns. Default both to `NOW()`.
    public func timestamps() {
        date("created_at").defaultNow()
        date("updated_at").defaultNow()
    }

    /// Adds a `deleted_at` date columns.
    public func softDeletes() {
        date("deleted_at")
    }

    /// Adds a column builder to this table builder & returns it.
    ///
    /// - Parameter builder: The column builder to add to this table
    ///   builder.
    /// - Returns: The passed in `builder`.
    private func appendAndReturn<T: SQLConvertible>( builder: CreateColumnBuilder<T>) -> CreateColumnBuilder<T> {
        columnBuilders.append(builder)
        return builder
    }
}
