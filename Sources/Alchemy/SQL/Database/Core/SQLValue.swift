import Foundation

/// Represents the type / value combo of an SQL database field. These
/// don't necessarily correspond to a specific SQL database's types;
/// they just represent the types that Alchemy current supports.
///
/// All fields are optional by default, it's up to the end user to
/// decide if a nil value in that field is appropriate and
/// potentially throw an error.
public enum SQLValue: Equatable, Hashable, CustomStringConvertible {
    /// An `Int` value.
    case int(Int)
    /// A `Double` value.
    case double(Double)
    /// A `Bool` value.
    case bool(Bool)
    /// A `String` value.
    case string(String)
    /// A `Date` value.
    case date(Date)
    /// A JSON value, given as `Data`.
    case json(Data)
    /// A `UUID` value.
    case uuid(UUID)
    /// A null value of any type.
    case null
    
    public var description: String {
        switch self {
        case .int(let int):
            return "\(int)"
        case .double(let double):
            return "\(double)"
        case .bool(let bool):
            return "\(bool)"
        case .string(let string):
            return "'\(string)'"
        case .date(let date):
            return "\(date)"
        case .json(let data):
            return "\(String(data: data, encoding: .utf8) ?? "\(data)")"
        case .uuid(let uuid):
            return "\(uuid.uuidString)"
        case .null:
            return "null"
        }
    }
    
    public static var now: SQLValue { .date(Date()) }
}

/// Extension for easily accessing the unwrapped contents of an `SQLValue`.
extension SQLValue {
    static let iso8601DateFormatter = ISO8601DateFormatter()
    static let simpleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    /// Unwrap and return an `Int` value from this `SQLValue`.
    /// This throws if the underlying `value` isn't an `.int` or
    /// the `.int` has a `nil` associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.int` or its contents is nil.
    /// - Returns: The unwrapped `Int` of this field's value, if it
    ///   was indeed a non-null `.int`.
    public func int(_ columnName: String? = nil) throws -> Int {
        try ensureNotNull(columnName)
        switch self {
        case .int(let value):
            return value
        case .date(let value):
            return Int(value.timeIntervalSince1970)
        default:
            throw typeError("Int", columnName: columnName)
        }
    }
    
    /// Unwrap and return a `String` value from this `SQLValue`.
    /// This throws if the underlying `value` isn't a `.string` or
    /// the `.string` has a nil associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.string` or its contents is nil.
    /// - Returns: The unwrapped `String` of this field's value, if
    ///   it was indeed a non-null `.string`.
    public func string(_ columnName: String? = nil) throws -> String {
        try ensureNotNull(columnName)
        switch self {
        case .string(let value):
            return value
        case .double(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        case .date(let value):
            return value.description
        case .uuid(let value):
            return value.uuidString
        case .json(let data):
            guard let string = String(data: data, encoding: .utf8) else {
                throw typeError("String", columnName: columnName)
            }

            return string
        default:
            throw typeError("String", columnName: columnName)
        }
    }
    
    /// Unwrap and return a `Double` value from this `SQLValue`.
    /// This throws if the underlying `value` isn't a `.double` or
    /// the `.double` has a nil associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.double` or its contents is nil.
    /// - Returns: The unwrapped `Double` of this field's value, if it
    ///   was indeed a non-null `.double`.
    public func double(_ columnName: String? = nil) throws -> Double {
        try ensureNotNull(columnName)
        switch self {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        case .date(let value):
            return value.timeIntervalSince1970
        default:
            throw typeError("Double", columnName: columnName)
        }
    }
    
    /// Unwrap and return a `Bool` value from this `SQLValue`.
    /// This throws if the underlying `value` isn't a `.bool` or
    /// the `.bool` has a nil associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.bool` or its contents is nil.
    /// - Returns: The unwrapped `Bool` of this field's value, if it
    ///   was indeed a non-null `.bool`.
    public func bool(_ columnName: String? = nil) throws -> Bool {
        try ensureNotNull(columnName)
        switch self {
        case .bool(let value):
            return value
        case .int(let value):
            return value != 0
        case .double(let value):
            return value != 0.0
        default:
            throw typeError("Bool", columnName: columnName)
        }
    }
    
    /// Unwrap and return a `Date` value from this `SQLValue`.
    /// This throws if the underlying `value` isn't a `.date` or
    /// the `.date` has a nil associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.date` or its contents is nil.
    /// - Returns: The unwrapped `Date` of this field's value, if it
    ///   was indeed a non-null `.date`.
    public func date(_ columnName: String? = nil) throws -> Date {
        try ensureNotNull(columnName)
        switch self {
        case .date(let value):
            return value
        case .int(let value):
            return Date(timeIntervalSince1970: Double(value))
        case .double(let value):
            return Date(timeIntervalSince1970: value)
        case .string(let value):
            guard
                let date = SQLValue.iso8601DateFormatter.date(from: value)
                    ?? SQLValue.simpleFormatter.date(from: value)
            else {
                throw typeError("Date", columnName: columnName)
            }

            return date
        default:
            throw typeError("Date", columnName: columnName)
        }
    }
    
    /// Unwrap and return a JSON `Data` value from this
    /// `SQLValue`. This throws if the underlying `value` isn't
    /// a `.json` or the `.json` has a nil associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.json` or its contents is nil.
    /// - Returns: The `Data` of this field's unwrapped json value, if
    ///   it was indeed a non-null `.json`.
    public func json(_ columnName: String? = nil) throws -> Data {
        try ensureNotNull(columnName)
        switch self {
        case .json(let value):
            return value
        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                throw typeError("JSON", columnName: columnName)
            }
            
            return data
        default:
            throw typeError("JSON", columnName: columnName)
        }
    }
    
    /// Unwrap and return a `UUID` value from this `SQLValue`.
    /// This throws if the underlying `value` isn't a `.uuid` or
    /// the `.uuid` has a nil associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.uuid` or its contents is nil.
    /// - Returns: The unwrapped `UUID` of this field's value, if it
    ///   was indeed a non-null `.uuid`.
    public func uuid(_ columnName: String? = nil) throws -> UUID {
        try ensureNotNull(columnName)
        switch self {
        case .uuid(let value):
            return value
        case .string(let string):
            guard let uuid = UUID(string) else {
                throw typeError("UUID", columnName: columnName)
            }
            
            return uuid
        default:
            throw typeError("UUID", columnName: columnName)
        }
    }
    
    private func typeError(_ typeName: String, columnName: String? = nil) -> Error {
        if let columnName = columnName {
            return DatabaseError("Unable to coerce \(self) at column `\(columnName)` to \(typeName)")
        }
        
        return DatabaseError("Unable to coerce \(self) to \(typeName).")
    }
    
    private func ensureNotNull(_ columnName: String? = nil) throws {
        if case .null = self {
            let desc = columnName.map { "column `\($0)`" } ?? "SQLValue"
            throw DatabaseError("Expected \(desc) to have a value but it was `nil`.")
        }
    }
}
