// For custom logic around attributes (ENUM, JSON, relationship, encrypted, filename, etc)
// then thin out decoder / encoder to check for this type and that's it? Then
// conform all types. Make it easy to add new types.
protocol ModelProperty {
//    init(key: String, on: SQLRow) throws
    init(field: SQLField) throws
    func toSQLField(at key: String) throws -> SQLField
}

extension ModelProperty {
    func toColumn(key: String) -> String { key }
    func toKey(column: String) -> String { column }
}

extension String: ModelProperty {
    init(field: SQLField) throws {
        self = try field.value.string()
    }
    
    func toSQLField(at key: String) throws -> SQLField {
        SQLField(column: key, value: .string(self))
    }
}

extension Bool: ModelProperty {
    init(field: SQLField) throws {
        self = try field.value.bool()
    }
    
    func toSQLField(at key: String) throws -> SQLField {
        SQLField(column: key, value: .bool(self))
    }
}

extension Float: ModelProperty {
    init(field: SQLField) throws {
        self = Float(try field.value.double())
    }
    
    func toSQLField(at key: String) throws -> SQLField {
        SQLField(column: key, value: .double(Double(self)))
    }
}

extension Double: ModelProperty {
    init(field: SQLField) throws {
        self = try field.value.double()
    }
    
    func toSQLField(at key: String) throws -> SQLField {
        SQLField(column: key, value: .double(self))
    }
}

extension FixedWidthInteger {
    init(field: SQLField) throws {
        self = try .init(field.value.int())
    }
    
    func toSQLField(at key: String) throws -> SQLField {
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
    init(field: SQLField) throws {
        self = try field.value.date()
    }
    
    func toSQLField(at key: String) throws -> SQLField {
        SQLField(column: key, value: .date(self))
    }
}

extension UUID: ModelProperty {
    init(field: SQLField) throws {
        self = try field.value.uuid()
    }
    
    func toSQLField(at key: String) throws -> SQLField {
        SQLField(column: key, value: .uuid(self))
    }
}
