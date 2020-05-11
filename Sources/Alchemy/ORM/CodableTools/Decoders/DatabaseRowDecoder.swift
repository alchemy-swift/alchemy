import Foundation

/// Decodes a `Decodable` from a `DatabaseRow`.
struct DatabaseRowDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let row: DatabaseRow
    let keyMappingStrategy: DatabaseKeyMappingStrategy
    
    init(row: DatabaseRow, keyMappingStrategy: DatabaseKeyMappingStrategy) {
        print("Got columns: \(row.allColumns)")
        self.row = row
        self.keyMappingStrategy = keyMappingStrategy
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedContainer(row: self.row, keyMappingStrategy: self.keyMappingStrategy))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
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
        let val = self.row.allColumns.contains(self.string(for: key))
        print("has key: \(self.string(for: key)) \(val)")
        print("keys: \(self.allKeys.map { $0.stringValue })")
        return val
    }
    
    /// Is the key nil?
    func decodeNil(forKey key: Key) throws -> Bool {
        print("Decode nil")
        return try self.row.getField(columnName: self.string(for: key)).value.isNil
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        print("Bool from \(key.stringValue)")
        return try self.row.getField(columnName: self.string(for: key)).bool()
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        print("String from \(key.stringValue)")
        return try self.row.getField(columnName: self.string(for: key)).string()
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        print("Double from \(key.stringValue)")
        return try self.row.getField(columnName: self.string(for: key)).double()
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        print("Float from \(key.stringValue)")
        return Float(try self.row.getField(columnName: self.string(for: key)).double())
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        print("Int from \(key.stringValue)")
        return try self.row.getField(columnName: self.string(for: key)).int()
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        print("Int8 from \(key.stringValue)")
        return Int8(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        print("Int16 from \(key.stringValue)")
        return Int16(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        print("Int32 from \(key.stringValue)")
        return Int32(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        print("Int64 from \(key.stringValue)")
        return Int64(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        print("UInt from \(key.stringValue)")
        return UInt(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        print("UInt8 from \(key.stringValue)")
        return UInt8(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        print("UInt16 from \(key.stringValue)")
        return UInt16(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        print("UInt32 from \(key.stringValue)")
        return UInt32(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        print("UInt64 from \(key.stringValue)")
        return UInt64(try self.row.getField(columnName: self.string(for: key)).int())
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        print("T from \(key.stringValue)")
        print("val: \(try self.row.getField(columnName: "price_status").string())")
        if type == UUID.self {
            return try self.row.getField(columnName: self.string(for: key)).uuid() as! T
        } else if type == Date.self {
            return try self.row.getField(columnName: self.string(for: key)).date() as! T
        } else {
            /// TODO: Use this for eager loading?
            print("key: \(self.string(for: key)), type: \(Swift.type(of: type))")
            throw DatabaseDecodingError("Nested database types aren't available, yet.")
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        print("Nested container")
        throw DatabaseDecodingError("This shouldn't be called? nextedContainer")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        print("Nested unkeyed")
        throw DatabaseDecodingError("This shouldn't be called? nestedUnkeyedContainer")
    }
    
    func superDecoder() throws -> Decoder {
        print("Super decoder")
        throw DatabaseDecodingError("This shouldn't be called? superDecoder")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        print("Super decoder for key")
        throw DatabaseDecodingError("This shouldn't be called? superDecoder(forKey:)")
    }
}
