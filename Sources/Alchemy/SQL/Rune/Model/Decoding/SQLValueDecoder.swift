/// Used in the internals of the `SQLRowDecoder`, used when
/// the `SQLRowDecoder` attempts to decode a `Decodable`,
/// not primitive, property from a single `SQLValue`.
struct SQLValueDecoder: ModelDecoder {
    /// The value this `Decoder` will be decoding from.
    let value: SQLValue
    let column: String
    
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
        _SingleValueDecodingContainer(value: value, column: column)
    }
}

/// A `SingleValueDecodingContainer` for decoding from an `SQLValue`.
private struct _SingleValueDecodingContainer: SingleValueDecodingContainer {
    /// The value from which to decode.
    let value: SQLValue
    let column: String
    
    // MARK: SingleValueDecodingContainer
    
    var codingPath: [CodingKey] = []
    
    func decodeNil() -> Bool {
        value == .null
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        try value.bool(column)
    }
    
    func decode(_ type: String.Type) throws -> String {
        try value.string(column)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        try value.double(column)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        Float(try value.double(column))
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try value.int(column)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        Int8(try value.int(column))
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        Int16(try value.int(column))
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        Int32(try value.int(column))
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        Int64(try value.int(column))
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        UInt(try value.int(column))
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        UInt8(try value.int(column))
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        UInt16(try value.int(column))
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        UInt32(try value.int(column))
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        UInt64(try value.int(column))
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if type == Int.self {
            return try value.int(column) as! T
        } else if type == UUID.self {
            return try value.uuid(column) as! T
        } else if type == String.self {
            return try value.string(column) as! T
        } else {
            throw DatabaseCodingError("Decoding a \(type) from a `SQLValue` is not supported. \(column)")
        }
    }
}
