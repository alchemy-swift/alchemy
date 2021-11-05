import Foundation

/// Represents the type / value combo of an SQL database field. These
/// don't necessarily correspond to a specific SQL database's types;
/// they just represent the types that Alchemy current supports.
///
/// All fields are optional by default, it's up to the end user to
/// decide if a nil value in that field is appropriate and
/// potentially throw an error.
public enum SQLValue: Equatable, Hashable {
    /// An `Int` value.
    case int(Int?)
    /// A `Double` value.
    case double(Double?)
    /// A `Bool` value.
    case bool(Bool?)
    /// A `String` value.
    case string(String?)
    /// A `Date` value.
    case date(Date?)
    /// A JSON value, given as `Data`.
    case json(Data?)
    /// A `UUID` value.
    case uuid(UUID?)
}

extension SQLValue {
    /// Indicates if the associated value inside this enum is nil.
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
        }
    }
}
