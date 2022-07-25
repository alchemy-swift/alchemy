// For custom logic around loading and saving properties on a Model.
public protocol ModelProperty {
    init(key: String, on row: SQLRowReader) throws
    func store(key: String, on row: inout SQLRowWriter) throws
}

extension String: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        self =  try row.require(key).string(key)
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(.string(self), at: key)
    }
}

extension Bool: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        self = try row.require(key).bool(key)
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(.bool(self), at: key)
    }
}

extension Float: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        self = Float(try row.require(key).double(key))
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(.double(Double(self)), at: key)
    }
}

extension Double: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        self =  try row.require(key).double(key)
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(.double(self), at: key)
    }
}

extension FixedWidthInteger {
    public init(key: String, on row: SQLRowReader) throws {
        self = try .init(row.require(key).int(key))
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(.int(Int(self)), at: key)
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
    public init(key: String, on row: SQLRowReader) throws {
        self = try row.require(key).date(key)
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(.date(self), at: key)
    }
}

extension UUID: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        self = try row.require(key).uuid(key)
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(.uuid(self), at: key)
    }
}

extension Optional: ModelProperty where Wrapped: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        guard row.contains(key) else {
            self = nil
            return
        }
        
        self = .some(try Wrapped(key: key, on: row))
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        try self?.store(key: key, on: &row)
    }
}
