/// Something that's convertible to an SQL statement or expression.
public protocol SQLConvertible {
    var sql: SQL { get }
}

extension SQLConvertible {
    /// The raw, non-parameterized version of this SQL query.
    public var rawSQLString: String {
        sql.rawSQLString
    }
}

extension SQL: SQLConvertible {
    public var sql: SQL { self }
}

extension SQLConvertible where Self == SQL {
    public static func raw(_ statement: String, input: [SQLValueConvertible]) -> SQLConvertible {
        SQL(statement, input: input)
    }

    public static func raw(_ sql: SQL) -> SQLConvertible {
        sql
    }

    public static var null: Self {
        SQLValue.null.sql
    }
}

extension SQLConvertible where Self == Query<SQLRow> {
    public static func select(_ columns: String...) -> Query<SQLRow> {
        Query(db: DB, columns: columns)
    }
}

extension SQLConvertible where Self == SQLValue {
    public static func value(_ value: SQLValue) -> Self {
        value
    }

    public static var now: Self {
        .date(Date())
    }
}
