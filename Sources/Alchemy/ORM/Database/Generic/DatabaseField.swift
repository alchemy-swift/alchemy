import Foundation

/// Represents a field on a database row.
public struct DatabaseField {
    /// Represents the type & value pair of a database row. Everything is implicitly nullable. It is left up
    /// to the consumer to determine whether a `nil` concrete value is acceptable or not (i.e. if that column
    /// is nullable).
    public indirect enum Value {
        /// Primitives.
        case int(Int?)
        case double(Double?)
        case bool(Bool?)
        case string(String?)
        case date(Date?)
        case json(Data?)
        case uuid(UUID?)
        
        /// Arrays.
        case arrayInt([Int]?)
        case arrayDouble([Double]?)
        case arrayBool([Bool]?)
        case arrayString([String]?)
        case arrayDate([Date]?)
        case arrayJSON([Data]?)
        case arrayUUID([UUID]?)
    }
    
    /// The name of the column this value came from.
    public let column: String
    /// The value of this field.
    public let value: Value
}
