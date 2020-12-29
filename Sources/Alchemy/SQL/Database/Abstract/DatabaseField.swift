/// Represents a column & value pair in a database row.
///
/// If there were a table with columns "id", "email", "phone" and a row with
/// values 1 ,"josh@alchemy.dev", "(555) 555-5555",
/// `DatabaseField(column: id, .int(1))` would represent a field on that table.
public struct DatabaseField: Equatable {
    /// The name of the column this value came from.
    public let column: String
    /// The value of this field.
    public let value: DatabaseValue
}

/// Functions for easily accessing the unwrapped contents of `DatabaseField`
/// values.
extension DatabaseField {
    /// Unwrap and return an `Int` value from this `DatabaseField`. This throws
    /// if the underlying `value` isn't an `.int` or the `.int` has a nil
    /// associated value.
    ///
    /// - Throws: a `DatabaseError` if this field's `value` isn't a
    ///           `DatabaseValue.int` or its contents is nil.
    /// - Returns: the unwrapped `Int` of this field's value, if it was indeed
    ///            a non-null `.int`.
    public func int() throws -> Int {
        guard case let .int(value) = self.value else {
            throw typeError("int")
        }
        
        return try self.unwrapOrError(value)
    }
    
    /// Unwrap and return a `String` value from this `DatabaseField`. This
    /// throws if the underlying `value` isn't a `.string` or the `.string` has
    /// a nil associated value.
    ///
    /// - Throws: a `DatabaseError` if this field's `value` isn't a
    ///           `DatabaseValue.string` or its contents is nil.
    /// - Returns: the unwrapped `String` of this field's value, if it was indeed
    ///            a non-null `.string`.
    public func string() throws -> String {
        guard case let .string(value) = self.value else {
            throw typeError("string")
        }
        
        return try self.unwrapOrError(value)
    }
    
    /// Unwrap and return a `Double` value from this `DatabaseField`. This
    /// throws if the underlying `value` isn't a `.double` or the `.double` has
    /// a nil associated value.
    ///
    /// - Throws: a `DatabaseError` if this field's `value` isn't a
    ///           `DatabaseValue.double` or its contents is nil.
    /// - Returns: the unwrapped `Double` of this field's value, if it was
    ///            indeed a non-null `.double`.
    public func double() throws -> Double {
        guard case let .double(value) = self.value else {
            throw typeError("double")
        }
        
        return try self.unwrapOrError(value)
    }
    
    /// Unwrap and return a `Bool` value from this `DatabaseField`. This throws
    /// if the underlying `value` isn't a `.bool` or the `.bool` has a nil
    /// associated value.
    ///
    /// - Throws: a `DatabaseError` if this field's `value` isn't a
    ///           `DatabaseValue.bool` or its contents is nil.
    /// - Returns: the unwrapped `Bool` of this field's value, if it was indeed
    ///            a non-null `.bool`.
    public func bool() throws -> Bool {
        guard case let .bool(value) = self.value else {
            throw typeError("bool")
        }
        
        return try self.unwrapOrError(value)
    }
    
    /// Unwrap and return a `Date` value from this `DatabaseField`. This throws
    /// if the underlying `value` isn't a `.date` or the `.date` has a nil
    /// associated value.
    ///
    /// - Throws: a `DatabaseError` if this field's `value` isn't a
    ///           `DatabaseValue.date` or its contents is nil.
    /// - Returns: the unwrapped `Date` of this field's value, if it was indeed
    ///            a non-null `.date`.
    public func date() throws -> Date {
        guard case let .date(value) = self.value else {
            throw typeError("date")
        }
        
        return try self.unwrapOrError(value)
    }
    
    /// Unwrap and return a JSON `Data` value from this `DatabaseField`. This
    /// throws if the underlying `value` isn't a `.json` or the `.json` has a
    /// nil associated value.
    ///
    /// - Throws: a `DatabaseError` if this field's `value` isn't a
    ///           `DatabaseValue.json` or its contents is nil.
    /// - Returns: the `Data` of this field's unwrapped json value, if it was
    ///            indeed a non-null `.json`.
    public func json() throws -> Data {
        guard case let .json(value) = self.value else {
            throw typeError("json")
        }
        
        return try self.unwrapOrError(value)
    }
    
    /// Unwrap and return a `UUID` value from this `DatabaseField`. This throws
    /// if the underlying `value` isn't a `.uuid` or the `.uuid` has a nil
    /// associated value.
    ///
    /// - Throws: a `DatabaseError` if this field's `value` isn't a
    ///           `DatabaseValue.uuid` or its contents is nil.
    /// - Returns: the unwrapped `UUID` of this field's value, if it was indeed
    ///            a non-null `.uuid`.
    public func uuid() throws -> UUID {
        guard case let .uuid(value) = self.value else {
            throw typeError("uuid")
        }
        
        return try self.unwrapOrError(value)
    }
    
    /// Generates an `DatabaseError` appropriate to throw if the user tries to
    /// get a type that isn't compatible with this `DatabaseField`'s `value`.
    ///
    /// - Parameter typeName: the name of the type the user tried to get.
    /// - Returns: a `DatabaseError` with a message describing the predicament.
    private func typeError(_ typeName: String) -> Error {
        DatabaseError("Field at column '\(self.column)' was not a `\(typeName)`")
    }
    
    /// Unwraps a value of type `T`, or throws an error detailing the nil data
    /// at the column.
    ///
    /// - Parameter value: the value to unwrap.
    /// - Throws: a `DatabaseError` if the value is nil.
    /// - Returns: the value, `T`, if it was successfully unwrapped.
    private func unwrapOrError<T>(_ value: T?) throws -> T {
        try value.unwrap(or: DatabaseError("Tried to get a value from '\(self.column)' but it was `nil`."))
    }
}
