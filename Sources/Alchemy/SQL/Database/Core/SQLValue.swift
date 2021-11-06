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

/// Extension for easily accessing the unwrapped contents of an `SQLValue`.
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
    
    /// Unwrap and return an `Int` value from this `SQLValue`.
    /// This throws if the underlying `value` isn't an `.int` or
    /// the `.int` has a `nil` associated value.
    ///
    /// - Throws: A `DatabaseError` if this field's `value` isn't a
    ///   `SQLValue.int` or its contents is nil.
    /// - Returns: The unwrapped `Int` of this field's value, if it
    ///   was indeed a non-null `.int`.
    public func int(_ columnName: String? = nil) throws -> Int {
        guard case let .int(value) = self else {
            throw typeError("int", columnName: columnName)
        }
        
        return try self.unwrapOrError(value, columnName: columnName)
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
        guard case let .string(value) = self else {
            throw typeError("string", columnName: columnName)
        }
        
        return try self.unwrapOrError(value, columnName: columnName)
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
        guard case let .double(value) = self else {
            throw typeError("double", columnName: columnName)
        }
        
        return try self.unwrapOrError(value, columnName: columnName)
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
        if case let .bool(value) = self {
            return try self.unwrapOrError(value, columnName: columnName)
        } else if case let .int(value) = self {
            return try self.unwrapOrError(value.map { $0 != 0 }, columnName: columnName)
        }
        
        throw typeError("bool", columnName: columnName)
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
        if case let .date(value) = self {
            return try self.unwrapOrError(value, columnName: columnName)
        } else if case let .string(value) = self {
            let formatter = ISO8601DateFormatter()
            if let value = value, let date = formatter.date(from: value) {
                return date
            }
            
            throw typeError("date", columnName: columnName)
        }
        
        throw typeError("date", columnName: columnName)
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
        guard case let .json(value) = self else {
            throw typeError("json", columnName: columnName)
        }
        
        return try self.unwrapOrError(value, columnName: columnName)
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
        guard case let .uuid(value) = self else {
            throw typeError("uuid", columnName: columnName)
        }
        
        return try self.unwrapOrError(value, columnName: columnName)
    }
    
    /// Generates an error appropriate to throw if the user tries to get a type
    /// that isn't compatible with this value.
    ///
    /// - Parameter typeName: The name of the type the user tried to get.
    /// - Returns: A `DatabaseError` with a message describing the predicament.
    private func typeError(_ typeName: String, columnName: String? = nil) -> Error {
        if let columnName = columnName {
            return DatabaseError("Field at column '\(columnName)' expected to be `\(typeName)` but wasn't.")
        }
        
        return DatabaseError("Unable to convert '\(self)' to a `\(typeName)`.")
    }
    
    /// Unwraps a value of type `T`, or throws an error detailing the
    /// nil data at the column.
    ///
    /// - Parameter value: The value to unwrap.
    /// - Throws: A `DatabaseError` if the value is nil.
    /// - Returns: The value, `T`, if it was successfully unwrapped.
    private func unwrapOrError<T>(_ value: T?, columnName: String? = nil) throws -> T {
        if let columnName = columnName {
            return try value.unwrap(or: DatabaseError("Tried to get a value from '\(columnName)' but it was `nil`."))
        }
        
        return try value.unwrap(or: DatabaseError("Tried to get a value from '\(self)' but it was `nil`."))
    }
}
