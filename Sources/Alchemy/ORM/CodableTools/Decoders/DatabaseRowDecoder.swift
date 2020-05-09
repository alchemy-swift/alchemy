/// Decodes a `Decodable` from a `DatabaseRow`.
struct DatabaseRowDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let row: DatabaseRow
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedContainer(row: self.row))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
    }
}

private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    /// Used for debugging I believe; ignoring for now.
    var codingPath: [CodingKey] = []
    
    var allKeys: [Key] {
        self.row.allColumns.compactMap { Key(stringValue: $0) }
    }
    
    let row: DatabaseRow
    
    func contains(_ key: Key) -> Bool {
        self.allKeys.contains { $0.stringValue == key.stringValue }
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        /// Does the DB have nil values?
        throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "no nils allowed"))
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try self.row.getField(columnName: key.stringValue).bool()
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try self.row.getField(columnName: key.stringValue).string()
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try self.row.getField(columnName: key.stringValue).double()
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        Float(try self.row.getField(columnName: key.stringValue).double())
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try self.row.getField(columnName: key.stringValue).int()
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        Int8(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        Int16(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        Int32(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        Int64(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        UInt(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        UInt8(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        UInt16(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        UInt32(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        UInt64(try self.row.getField(columnName: key.stringValue).int())
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        /// TODO: Use this for eager loading?
        throw DatabaseDecodingError("Nested database types aren't available, yet.")
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw DatabaseDecodingError("This shouldn't be called? nextedContainer")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw DatabaseDecodingError("This shouldn't be called? nestedUnkeyedContainer")
    }
    
    func superDecoder() throws -> Decoder {
        throw DatabaseDecodingError("This shouldn't be called? superDecoder")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        throw DatabaseDecodingError("This shouldn't be called? superDecoder(forKey:)")
    }
}
