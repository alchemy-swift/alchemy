import Foundation

public indirect enum DatabaseValue {
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

extension DatabaseValue {
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
    
    /// Gives a database appropriate string representation of this value, even if it isn't a string. Note,
    /// this does not add single quotes (') for anything.
    public var stringified: String {
        switch self {
        case .int(let value):
            return value.map { "\($0)" } ?? "NULL"
        case .double(let value):
            return value.map { "\($0)" } ?? "NULL"
        case .bool(let value):
            return value.map { "\($0)" } ?? "NULL"
        case .string(let value):
            // ' -> '' is escape for MySQL & Postgres... not sure if this will break elsewhere.
            return value.map { "'\($0.replacingOccurrences(of: "'", with: "''"))'" } ?? "NULL"
        case .date(let value):
            return value.map { "'\($0)'" } ?? "NULL"
        case .json(_):
            fatalError()
        case .uuid(let value):
            return value.map { "'\($0.uuidString)'" } ?? "NULL"
        case .arrayInt(_):
            fatalError()
        case .arrayDouble(_):
            fatalError()
        case .arrayBool(_):
            fatalError()
        case .arrayString(_):
            fatalError()
        case .arrayDate(_):
            fatalError()
        case .arrayJSON(_):
            fatalError()
        case .arrayUUID(_):
            fatalError()
        }
    }
}
