import Foundation

public enum SQLParameter: Hashable, SQLParameterConvertible {
    /// A raw SQL expression such as "NOW()".
    case expression(SQL)
    /// An value that can be bound to a query parameter, such as `"Josh"` or `26`.
    case value(SQLValue)

    public var sqlParameter: SQLParameter { self }

    public var rawSQLString: String {
        switch self {
        case .expression(let sql):
            return sql.rawSQLString
        case .value(let value):
            return value.rawSQLString
        }
    }
}
