import Foundation

extension DatabaseField {
    public func int() throws -> Int {
        guard case let .int(value) = self.value else {
            throw PostgresError(message: "Field at column '\(self.column)' was not an `int`.")
        }
        
        return value
    }
    
    public func string() throws -> String {
        guard case let .string(value) = self.value else {
            throw PostgresError(message: "Field at column '\(self.column)' was not a `string`.")
        }
        
        return value
    }
    
    public func double() throws -> Double {
        guard case let .double(value) = self.value else {
            throw PostgresError(message: "Field at column '\(self.column)' was not a `double`.")
        }
        
        return value
    }
    
    public func bool() throws -> Bool {
        guard case let .bool(value) = self.value else {
            throw PostgresError(message: "Field at column '\(self.column)' was not an `bool`.")
        }
        
        return value
    }
    
    public func date() throws -> Date {
        guard case let .date(value) = self.value else {
            throw PostgresError(message: "Field at column '\(self.column)' was not a `date`.")
        }
        
        return value
    }
    
    public func json() throws -> Data {
        guard case let .json(value) = self.value else {
            throw PostgresError(message: "Field at column '\(self.column)' was not a `json`.")
        }
        
        return value
    }
    
    public func uuid() throws -> UUID {
        guard case let .uuid(value) = self.value else {
            throw PostgresError(message: "Field at column '\(self.column)' was not a `uuid`.")
        }
        
        return value
    }
}
