import Foundation

/// Decodes a `Decodable` from a `DatabaseRow`.
struct DatabaseRowDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let row: DatabaseRow
    let keyMappingStrategy: DatabaseKeyMappingStrategy
    
    init(row: DatabaseRow, keyMappingStrategy: DatabaseKeyMappingStrategy) {
        self.row = row
        self.keyMappingStrategy = keyMappingStrategy
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedContainer(row: self.row, keyMappingStrategy: self.keyMappingStrategy))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        /// This is for arrays, which we currently support in other ways.
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
    }
}

private struct DatabaseFieldDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let field: DatabaseField
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        throw DatabaseDecodingError("`container` shouldn't be called; this is only for single values.")
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DatabaseDecodingError("`unkeyedContainer` shouldn't be called; this is only for single values.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        _SingleValueDecodingContainer(field: self.field)
    }
}

private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    /// Used for debugging only I believe; ignoring for now.
    var codingPath: [CodingKey] = []
    
    /// From what I can tell this is only used in custom `decodes` (which we will explicitly say not to do
    /// since it will break a lot of database coding logic).
    ///
    /// Can't populate here since there is no way to match database column strings to the original coding key,
    /// without an inverse of the `DatabaseKeyMappingStrategy`.
    ///
    /// Consider coding key `userID` that when using snake case mapping gets mapped to `user_id`. We coudln't
    /// convert that back properly, since there would be no way to know if it was `userId` or `userID`.
    var allKeys: [Key] {
        []
    }
    
    let row: DatabaseRow
    let keyMappingStrategy: DatabaseKeyMappingStrategy
    
    private func string(for key: Key) -> String {
        self.keyMappingStrategy.map(input: key.stringValue)
    }
    
    func contains(_ key: Key) -> Bool {
        return self.row.allColumns.contains(self.string(for: key))
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        return try self.row.getField(column: self.string(for: key)).value.isNil
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        return try self.row.getField(column: self.string(for: key)).bool()
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        return try self.row.getField(column: self.string(for: key)).string()
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        return try self.row.getField(column: self.string(for: key)).double()
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        return Float(try self.row.getField(column: self.string(for: key)).double())
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        return try self.row.getField(column: self.string(for: key)).int()
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        return Int8(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        return Int16(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        return Int32(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        return Int64(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        return UInt(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        return UInt8(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        return UInt16(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        return UInt32(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        return UInt64(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        if type == UUID.self {
            return try self.row.getField(column: self.string(for: key)).uuid() as! T
        } else if type == Date.self {
            return try self.row.getField(column: self.string(for: key)).date() as! T
        } else if type is AnyBelongsTo.Type {
            let field = try self.row.getField(column: self.string(for: key) + "_id")
            return try T(from: DatabaseFieldDecoder(field: field))
        } else if type is AnyHas.Type {
            // Special case the AnyHas to decode the coding key.
            return try T(from: DatabaseFieldDecoder(field: .init(column: "key", value: .string(key.stringValue))))
        } else {
            let field = try self.row.getField(column: self.string(for: key))
            return try T(from: DatabaseFieldDecoder(field: field))
        }
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

private struct _SingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    
    let field: DatabaseField
    
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
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if type == Int.self {
            return try self.field.int() as! T
        } else if type == UUID.self {
            return try self.field.uuid() as! T
        } else {
            throw DatabaseError("Decode a type from a single value container is not supported \(type).")
        }
    }
}
