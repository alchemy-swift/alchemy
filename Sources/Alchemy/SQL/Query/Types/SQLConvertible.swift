import Foundation

/// Something that can be turned into SQL.
public protocol SQLConvertible {
    /// Returns an SQL representation of this type.
    func toSQL() -> SQL
}
