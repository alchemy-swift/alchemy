/// A type erased `CreateColumnBuilder`.
protocol ColumnBuilderErased {
    /// Generate the `CreateColumn` data associated with this builder.
    func toCreate() -> CreateColumn
}

/// Options for an `onDelete` or `onUpdate` reference constraint.
public enum ReferenceOption: String {
    /// RESTRICT
    case restrict = "RESTRICT"
    /// CASCADE
    case cascade = "CASCADE"
    /// SET NULL
    case setNull = "SET NULL"
    /// NO ACTION
    case noAction = "NO ACTION"
    /// SET DEFAULT
    case setDefault = "SET DEFAULT"
}

/// Various constraints for columns.
enum ColumnConstraint {
    /// This column shouldn't be null.
    case notNull
    /// The default value for this column.
    case `default`(String)
    /// This column is the primary key of it's table.
    case primaryKey
    /// This column is unique on this table.
    case unique
    /// This column references a `column` on another `table`.
    case foreignKey(
            column: String,
            table: String,
            onDelete: ReferenceOption? = nil,
            onUpdate: ReferenceOption? = nil
         )
    /// This int column is unsigned.
    case unsigned
}

/// A builder for creating columns on a table in a relational database.
///
/// `Default` is a Swift type that can be used to add a default value
/// to this column.
public final class CreateColumnBuilder<Default: Sequelizable>: ColumnBuilderErased {
    /// The grammar of this builder.
    private let grammar: Grammar
    
    /// The name of the column.
    private let name: String
    
    /// The type string of the column.
    private let type: ColumnType
    
    /// Any modifiers of the column.
    private var constraints: [ColumnConstraint]
    
    /// Create with a name, a type, and a modifier array.
    ///
    /// - Parameters:
    ///   - grammar: The grammar with which to compile statements from
    ///     this builder.
    ///   - name: The name of the column to create.
    ///   - type: The type of the column to create.
    ///   - modifiers: Any modifiers of the column.
    init(grammar: Grammar, name: String, type: ColumnType, constraints: [ColumnConstraint] = []) {
        self.grammar = grammar
        self.name = name
        self.type = type
        self.constraints = constraints
    }
    
    /// Adds an expression as the default value of this column.
    ///
    /// - Parameter expression: An expression for generating the
    ///   default value of this column.
    /// - Returns: This column builder.
    @discardableResult public func `default`(expression: String) -> Self {
        self.adding(constraint: .default(expression))
    }
    
    /// Adds a value as the default for this column.
    ///
    /// - Parameter expression: A default value for this column.
    /// - Returns: This column builder.
    @discardableResult public func `default`(val: Default) -> Self {
        // Janky, but MySQL requires parentheses around text (but not
        // varchar...) literals.
        if case .string(.unlimited) = self.type, self.grammar is MySQLGrammar {
            return self.adding(constraint: .default("(\(val.toSQL().query))"))
        }
        
        return self.adding(constraint: .default(val.toSQL().query))
    }
    
    /// Define this column as not nullable.
    ///
    /// - Returns: This column builder.
    @discardableResult public func notNull() -> Self {
        self.adding(constraint: .notNull)
    }
    
    /// Defines this column as a reference to another column on a
    /// table.
    ///
    /// - Parameters:
    ///   - column: The column name this column references.
    ///   - table: The table of the column this column references.
    ///   - onDelete: The `ON DELETE` reference option for this
    ///     column. Defaults to nil.
    ///   - onUpdate: The `ON UPDATE` reference option for this
    ///     column. Defaults to nil.
    /// - Returns: This column builder.
    @discardableResult public func references(
        _ column: String,
        on table: String,
        onDelete: ReferenceOption? = nil,
        onUpdate: ReferenceOption? = nil
    ) -> Self {
        self.adding(constraint: .foreignKey(column: column, table: table, onDelete: onDelete, onUpdate: onUpdate))
    }
    
    /// Defines this column as a primary key.
    ///
    /// - Returns: This column builder.
    @discardableResult public func primary() -> Self {
        self.adding(constraint: .primaryKey)
    }
    
    /// Defines this column as unique.
    ///
    /// - Returns: This column builder.
    @discardableResult public func unique() -> Self {
        self.adding(constraint: .unique)
    }
    
    /// Adds a modifier to `self.modifiers` and then returns `self`.
    ///
    /// - Parameter modifier: The modifier to add.
    /// - Returns: This column builder.
    private func adding(constraint: ColumnConstraint) -> Self {
        self.constraints.append(constraint)
        return self
    }

    // MARK: ColumnBuilderErased
    
    func toCreate() -> CreateColumn {
        CreateColumn(column: self.name, type: self.type, constraints: self.constraints)
    }
}

extension CreateColumnBuilder where Default == Int {
    /// Defines this integer column as unsigned.
    ///
    /// - Note: Ignored if the backing Database is `PostgresDatabase`.
    ///
    /// - Returns: This column builder.
    @discardableResult public func unsigned() -> Self {
        self.adding(constraint: .unsigned)
    }
}

/// Extensions for adding default values to a JSON column.
extension CreateColumnBuilder where Default == SQLJSON {
    /// Adds a JSON `String` as the default for this column.
    ///
    /// - Parameter jsonString: A JSON `String` to set as the default
    ///   for this column.
    /// - Returns: This column builder.
    @discardableResult public func `default`(jsonString: String) -> Self {
        self.adding(constraint: .default(self.grammar.jsonLiteral(from: jsonString)))
    }
    
    /// Adds an `Encodable` as the default for this column.
    ///
    /// - Parameters:
    ///   - json: Some `Encodable` type to encode and set as the
    ///     default value for this column.
    ///   - encoder: An `Encoder` for encoding the `json` parameter.
    ///     Defaults to `JSONEncoder()`.
    /// - Returns: This column builder.
    @discardableResult public func `default`<E: Encodable>(
        json: E,
        encoder: JSONEncoder = JSONEncoder()
    ) -> Self {
        guard let jsonData = try? encoder.encode(json) else {
            fatalError("Unable to encode JSON of type `\(E.self)` during migration.")
        }
        
        let jsonString = String(decoding: jsonData, as: UTF8.self)
        return self.adding(constraint: .default(self.grammar.jsonLiteral(from: jsonString)))
    }
}

extension Bool: Sequelizable {
    public func toSQL() -> SQL { SQL("\(self)") }
}

extension UUID: Sequelizable {
    public func toSQL() -> SQL { SQL("'\(self.uuidString)'") }
}

extension String: Sequelizable {
    public func toSQL() -> SQL { SQL("'\(self)'") }
}

extension Int: Sequelizable {
    public func toSQL() -> SQL { SQL("\(self)") }
}

extension Double: Sequelizable {
    public func toSQL() -> SQL { SQL("\(self)") }
}

extension Date: Sequelizable {
    /// The date formatter for turning this `Date` into an SQL string.
    private static let sqlFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = TimeZone(abbreviation: "GMT")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return df
    }()
    
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL("'\(Date.sqlFormatter.string(from: self))'") }
}

/// A type used to signify that a column on a database has a JSON
/// type.
///
/// This type can't be instantiated and so can't be passed to the
/// generic `default` function on `CreateColumnBuilder`. Instead,
/// opt to use `.default(jsonString:)` or `.default(encodable:)`
/// to set a default value for a JSON column.
public struct SQLJSON: Sequelizable {
    /// `init()` is kept private to this from ever being instantiated.
    private init() {}
    
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL() }
}
