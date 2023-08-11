/// A type for keeping track of data associated with creating an
/// column.
public struct CreateColumn {
    /// The name for this column.
    let name: String

    /// The type string.
    let type: ColumnType
    
    /// Any constraints.
    let constraints: [ColumnConstraint]

    /// Should this column be updated, rather than created.
    let isUpdate: Bool
}

/// An abstraction around various supported SQL column types.
/// `Grammar`s will map the `ColumnType` to the backing
/// grammar type string.
public enum ColumnType: Equatable {
    /// The length of an SQL string column in characters.
    public enum StringLength: Equatable {
        /// This value of this column can be any number of characters.
        case unlimited
        /// This value of this column must be at most the provided number
        /// of characters.
        case limit(Int)
    }
    
    /// Self incrementing integer.
    case increments
    /// Integer.
    case int
    /// Big integer.
    case bigInt
    /// Double.
    case double
    /// String, with a given max length.
    case string(StringLength)
    /// UUID.
    case uuid
    /// Boolean.
    case bool
    /// Date.
    case date
    /// JSON.
    case json
}

/// Various constraints for columns.
public enum ColumnConstraint {
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
    
    /// This column can be null.
    case nullable
    /// This column shouldn't be null.
    case notNull
    /// The default value for this column.
    case `default`(String)
    /// This column is the primary key of it's table.
    case primaryKey
    /// This column is unique on this table.
    case unique
    /// This column references a `column` on another `table`.
    case foreignKey(column: String,
                    table: String,
                    onDelete: ReferenceOption? = nil,
                    onUpdate: ReferenceOption? = nil)
    /// This int column is unsigned.
    case unsigned
}
