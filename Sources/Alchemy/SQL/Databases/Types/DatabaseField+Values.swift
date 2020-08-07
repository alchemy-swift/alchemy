import Foundation

extension DatabaseField {
    public func int() throws -> Int {
        guard case let .int(value) = self.value else { throw typeError("int") }
        return try self.unwrapOrError(value)
    }
    
    public func string() throws -> String {
        guard case let .string(value) = self.value else { throw typeError("string") }
        return try self.unwrapOrError(value)
    }
    
    public func double() throws -> Double {
        guard case let .double(value) = self.value else { throw typeError("double") }
        return try self.unwrapOrError(value)
    }
    
    public func bool() throws -> Bool {
        guard case let .bool(value) = self.value else { throw typeError("bool") }
        return try self.unwrapOrError(value)
    }
    
    public func date() throws -> Date {
        guard case let .date(value) = self.value else { throw typeError("date") }
        return try self.unwrapOrError(value)
    }
    
    public func json() throws -> Data {
        guard case let .json(value) = self.value else { throw typeError("json") }
        return try self.unwrapOrError(value)
    }
    
    public func uuid() throws -> UUID {
        guard case let .uuid(value) = self.value else { throw typeError("uuid") }
        return try self.unwrapOrError(value)
    }
    
    private func typeError(_ typeName: String) -> Error {
        PostgresError("Field at column '\(self.column)' was not a `\(typeName)`")
    }
    
    private func unwrapOrError<T>(_ value: T?) throws -> T {
        try value.unwrap(or: PostgresError("Tried to get a value from '\(self.column)' but it was `nil`."))
    }
}
