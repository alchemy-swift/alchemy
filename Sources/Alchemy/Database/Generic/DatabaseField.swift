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

extension DatabaseField.Value {
    public var isNil: Bool {
        switch self {
        case .int(let value):
            return value == nil
        case .double(let value):
            return value == nil
        case .bool(let value):
            return value == nil
        case .string(let value):
            return value == nil
        case .date(let value):
            return value == nil
        case .json(let value):
            return value == nil
        case .uuid(let value):
            return value == nil
        case .arrayInt(let value):
            return value == nil
        case .arrayDouble(let value):
            return value == nil
        case .arrayBool(let value):
            return value == nil
        case .arrayString(let value):
            return value == nil
        case .arrayDate(let value):
            return value == nil
        case .arrayJSON(let value):
            return value == nil
        case .arrayUUID(let value):
            return value == nil
        }
    }
}

private extension Optional {
    func nullOr(_ stringMap: (Wrapped) -> String) -> String {
        self.map(stringMap) ?? "NULL"
    }
}