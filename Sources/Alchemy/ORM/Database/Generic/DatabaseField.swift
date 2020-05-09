import Foundation

/// Represents a field on a database row.
public struct DatabaseField {
    public indirect enum Value {
        case int(Int)
        case double(Double)
        case bool(Bool)
        case string(String)
        case date(Date)
        case json(Data)
        case uuid(UUID)
        case array(Value)
    }
    
    public let column: String
    public let value: Value
}

extension DatabaseField: Equatable {
    public static func == (lhs: DatabaseField, rhs: DatabaseField) -> Bool {
        lhs.column == rhs.column && lhs.value == rhs.value
    }
}

extension DatabaseField.Value: Equatable {
    public static func == (lhs: DatabaseField.Value, rhs: DatabaseField.Value) -> Bool {
        if case .int = lhs, case .int = rhs {
            return true
        } else if case .double = lhs, case .double = rhs {
            return true
        } else if case .bool = lhs, case .bool = rhs {
            return true
        } else if case .string = lhs, case .string = rhs {
            return true
        } else if case .date = lhs, case .date = rhs {
            return true
        } else if case .json = lhs, case .json = rhs {
            return true
        } else if case .uuid = lhs, case .uuid = rhs {
            return true
        } else if case .array(let lhsValue) = lhs, case .array(let rhsValue) = rhs {
            return lhsValue == rhsValue
        } else {
            return false
        }
    }
}
