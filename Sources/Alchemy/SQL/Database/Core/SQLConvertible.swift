/// Something that can be turned into SQL.
public protocol SQLConvertible {
    /// Returns an SQL representation of this type.
    var sql: SQL { get }
}
