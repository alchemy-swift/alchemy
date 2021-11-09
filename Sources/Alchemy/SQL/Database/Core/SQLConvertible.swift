/// Something that can be turned into SQL.
public protocol SQLConvertible {
    /// Returns an SQL representation of this type.
    var sql: SQL { get }
}

extension SQLValueConvertible {
    public var sql: SQL {
        SQL(sqlString)
    }
}
