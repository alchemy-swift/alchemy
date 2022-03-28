// For custom logic around attributes (ENUM, JSON, relationship, encrypted, filename, etc)
// then thin out decoder / encoder to check for this type and that's it? Then
// conform all types. Make it easy to add new types.
public protocol ModelProperty {
    init(key: String, on row: SQLRowView) throws
    func toSQLField(at key: String) throws -> SQLField?
}

// A lightweight wrapper around an SQLRow that helps map keys.
public struct SQLRowView {
    let row: SQLRow
    let keyMapping: DatabaseKeyMapping
    
    public func require(_ key: String) throws -> SQLValue {
        try row.require(keyMapping.map(input: key))
    }
    
    public func contains(_ column: String) -> Bool {
        row[keyMapping.map(input: column)] != nil
    }
    
    public subscript(_ index: Int) -> SQLValue {
        row[index]
    }
    
    public subscript(_ column: String) -> SQLValue? {
        row[keyMapping.map(input: column)]
    }
}

extension String: ModelProperty {
    public init(key: String, on row: SQLRowView) throws {
        self =  try row.require(key).string()
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        SQLField(column: key, value: .string(self))
    }
}

extension Bool: ModelProperty {
    public init(key: String, on row: SQLRowView) throws {
        self = try row.require(key).bool()
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        SQLField(column: key, value: .bool(self))
    }
}

extension Float: ModelProperty {
    public init(key: String, on row: SQLRowView) throws {
        self = Float(try row.require(key).double())
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        SQLField(column: key, value: .double(Double(self)))
    }
}

extension Double: ModelProperty {
    public init(key: String, on row: SQLRowView) throws {
        self =  try row.require(key).double()
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        SQLField(column: key, value: .double(self))
    }
}

extension FixedWidthInteger {
    public init(key: String, on row: SQLRowView) throws {
        self = try .init(row.require(key).int())
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        SQLField(column: key, value: .int(Int(self)))
    }
}

extension Int: ModelProperty {}
extension Int8: ModelProperty {}
extension Int16: ModelProperty {}
extension Int32: ModelProperty {}
extension Int64: ModelProperty {}
extension UInt: ModelProperty {}
extension UInt8: ModelProperty {}
extension UInt16: ModelProperty {}
extension UInt32: ModelProperty {}
extension UInt64: ModelProperty {}

extension Date: ModelProperty {
    public init(key: String, on row: SQLRowView) throws {
        self = try row.require(key).date()
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        SQLField(column: key, value: .date(self))
    }
}

extension UUID: ModelProperty {
    public init(key: String, on row: SQLRowView) throws {
        self = try row.require(key).uuid()
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        SQLField(column: key, value: .uuid(self))
    }
}

extension Optional: ModelProperty where Wrapped: ModelProperty {
    public init(key: String, on row: SQLRowView) throws {
        guard row.contains(key) else {
            self = nil
            return
        }
        
        self = .some(try Wrapped(key: key, on: row))
    }
    
    public func toSQLField(at key: String) throws -> SQLField? {
        try self?.toSQLField(at: key)
    }
}
