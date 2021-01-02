/// Used in the internals of the `DatabaseRowDecoder`, this is for when the `DatabaseRowDecoder`
/// attempts to decode a `Decodable`, not primitive, property from a single `DatabaseField`.
struct DatabaseFieldDecoder: Decoder {
    /// The field this `Decoder` will be decoding from.
    let field: DatabaseField
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        throw DatabaseCodingError("`container` shouldn't be called; this is only for single "
                                        + "values.")
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DatabaseCodingError("`unkeyedContainer` shouldn't be called; this is only for "
                                        + "single values.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        _SingleValueDecodingContainer(field: self.field)
    }
}

/// A `SingleValueDecodingContainer` for decoding from a `DatabaseField`.
private struct _SingleValueDecodingContainer: SingleValueDecodingContainer {
    /// The field from which the container will be decoding from.
    let field: DatabaseField
    
    // MARK: SingleValueDecodingContainer
    
    var codingPath: [CodingKey] = []
    
    func decodeNil() -> Bool {
        self.field.value.isNil
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        try self.field.bool()
    }
    
    func decode(_ type: String.Type) throws -> String {
        try self.field.string()
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        try self.field.double()
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        Float(try self.field.double())
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try self.field.int()
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        Int8(try self.field.int())
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        Int16(try self.field.int())
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        Int32(try self.field.int())
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        Int64(try self.field.int())
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        UInt(try self.field.int())
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        UInt8(try self.field.int())
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        UInt16(try self.field.int())
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        UInt32(try self.field.int())
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        UInt64(try self.field.int())
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if type == Int.self {
            return try self.field.int() as! T
        } else if type == UUID.self {
            return try self.field.uuid() as! T
        } else {
            throw DatabaseCodingError("Decoding a \(type) from a `DatabaseField` is not supported.")
        }
    }
}
