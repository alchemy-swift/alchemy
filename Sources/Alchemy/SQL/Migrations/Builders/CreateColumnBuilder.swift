/// A type erased `CreateColumnBuilder`.
protocol ColumnBuilderErased {
    /// Generate the `CreateColumn` data associated with this builder.
    func toCreate() -> CreateColumn
}

/// A builder for creating columns on a table in a relational database.
///
/// `Default` is a Swift type that can be used to add a default value to this column.
public final class CreateColumnBuilder<Default: Sequelizable>: ColumnBuilderErased {
    /// The name of the column.
    private let name: String
    
    /// The type string of the column.
    private let type: String
    
    /// Any modifiers of the column.
    private var modifiers: [String]
    
    /// Create with a name, a type, and a modifier array.
    ///
    /// - Parameters:
    ///   - name: the name of the column to create.
    ///   - type: the type of the column to create.
    ///   - modifiers: any modifiers of the column.
    init(name: String, type: String, modifiers: [String] = []) {
        self.name = name
        self.type = type
        self.modifiers = modifiers
    }
    
    /// Adds an expression as the default value of this column.
    ///
    /// - Parameter expression: an expression for generating the default value of this column.
    /// - Returns: this column builder.
    @discardableResult public func `default`(expression: String) -> Self {
        self.appending(modifier: "DEFAULT \(expression)")
    }
    
    /// Adds a value as the default for this column.
    ///
    /// - Parameter expression: a default value for this column.
    /// - Returns: this column builder.
    @discardableResult public func `default`(val: Default) -> Self {
        self.appending(modifier: "DEFAULT \(val.toSQL().query)")
    }
    
    /// Define this column as not nullable.
    ///
    /// - Returns: this column builder.
    @discardableResult public func notNull() -> Self {
        self.appending(modifier: "NOT NULL")
    }
    
    /// Defines this column as a reference to another column on a table.
    ///
    /// - Parameters:
    ///   - column: the column name this column references.
    ///   - table: the table of the column this column references.
    /// - Returns: this column builder.
    @discardableResult public func references(_ column: String, on table: String) -> Self {
        self.appending(modifier: "REFERENCES \(table)(\(column))")
    }
    
    /// Defines this column as a primary key.
    ///
    /// - Returns: this column builder.
    @discardableResult public func primary() -> Self {
        self.appending(modifier: "PRIMARY KEY")
    }
    
    /// Defines this column as unique.
    ///
    /// - Returns: this column builder.
    @discardableResult public func unique() -> Self {
        self.appending(modifier: "UNIQUE")
    }
    
    /// Adds a modifier to `self.modifiers` and then returns `self`.
    ///
    /// - Parameter modifier: the modifier to add.
    /// - Returns: `self`.
    private func appending(modifier: String) -> Self {
        self.modifiers.append(modifier)
        return self
    }

    // MARK: ColumnBuilderErased
    
    func toCreate() -> CreateColumn {
        CreateColumn(column: self.name, type: self.type, constraints: self.modifiers)
    }
}

/// Extensions for adding default values to a JSON column.
extension CreateColumnBuilder where Default == SQLJSON {
    /// Adds a JSON `String` as the default for this column.
    ///
    /// - Parameter jsonString: a JSON `String` to set as the default for this column.
    /// - Returns: this column builder.
    @discardableResult public func `default`(jsonString: String) -> Self {
        self.appending(modifier: "DEFAULT '\(jsonString)'::jsonb")
    }
    
    /// Adds an `Encodable` as the default for this column.
    ///
    /// - Parameters:
    ///   - json: some `Encodable` type to encode and set as the default value for this column.
    ///   - encoder: an `Encoder` for encoding the `json` parameter. Defaults to `JSONEncoder()`.
    /// - Throws: any error encountered during encoding.
    /// - Returns: this column builder.
    @discardableResult public func `default`<E: Encodable>(
        json: E,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> Self {
        let jsonData = try encoder.encode(json)
        let jsonString = String(decoding: jsonData, as: UTF8.self)
        return self.appending(modifier: "DEFAULT '\(jsonString)'::jsonb")
    }
}

extension Bool: Sequelizable {
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL("\(self)") }
}

extension UUID: Sequelizable {
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL("'\(self.uuidString)'") }
}

extension String: Sequelizable {
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL("'\(self)'") }
}

extension Int: Sequelizable {
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL("\(self)") }
}

extension Double: Sequelizable {
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL("\(self)") }
}

extension Date: Sequelizable {
    /// The date formatter for turning this `Date` into an SQL string.
    private static let sqlFormatter = ISO8601DateFormatter()
    
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL("\(Date.sqlFormatter.string(from: self))") }
}

/// A type used to signify that a column on a database has a JSON type.
///
/// This type can't be instantiated and so can't be passed to the generic `default` function on
/// `CreateColumnBuilder`. Instead, opt to use `.default(jsonString:)` or `.default(encodable:)` to
/// set a default value for a JSON column.
public struct SQLJSON: Sequelizable {
    /// `init()` is kept private to this from ever being instantiated.
    private init() {}
    
    // MARK: Sequelizable
    
    public func toSQL() -> SQL { SQL() }
}
