import Foundation

/// Represents a field on a database row.
public struct DatabaseField {
    /// Represents the type & value pair of a database row. Everything is implicitly nullable. It is left up
    /// to the consumer to determine whether a `nil` concrete value is acceptable or not (i.e. if that column
    /// is nullable).
    
    /// The name of the column this value came from.
    public let column: String
    /// The value of this field.
    public let value: DatabaseValue
}

private extension Optional {
    func nullOr(_ stringMap: (Wrapped) -> String) -> String {
        self.map(stringMap) ?? "NULL"
    }
}
