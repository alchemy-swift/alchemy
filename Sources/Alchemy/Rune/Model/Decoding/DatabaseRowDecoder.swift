import Foundation

/// Decoder for decoding `Model` types from a `DatabaseRow`.
/// Properties of the `Decodable` type are matched to
/// columns with matching names (either the same
/// name or a specific name mapping based on
/// the supplied `keyMappingStrategy`).
struct DatabaseRowDecoder<M: Model>: Decoder {
    /// The row that will be decoded out of.
    let row: DatabaseRow
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(
            KeyedContainer<Key, M>(row: self.row)
        )
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        /// This is for arrays, which we don't support.
        throw DatabaseCodingError("This shouldn't be called; top level is keyed.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        /// This is for non-primitives that encode to a single value
        /// and should be handled by `DatabaseFieldDecoder`.
        throw DatabaseCodingError("This shouldn't be called; top level is keyed.")
    }
}

/// A `KeyedDecodingContainerProtocol` used to decode keys from a
/// `DatabaseRow`.
private struct KeyedContainer<Key: CodingKey, M: Model>: KeyedDecodingContainerProtocol {
    /// The row to decode from.
    let row: DatabaseRow
    
    // MARK: KeyedDecodingContainerProtocol
    
    var codingPath: [CodingKey] = []
    var allKeys: [Key] { [] }
    
    func contains(_ key: Key) -> Bool {
        self.row.allColumns.contains(self.string(for: key))
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        try self.row.getField(column: self.string(for: key)).value.isNil
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try self.row.getField(column: self.string(for: key)).bool()
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try self.row.getField(column: self.string(for: key)).string()
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try self.row.getField(column: self.string(for: key)).double()
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        Float(try self.row.getField(column: self.string(for: key)).double())
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try self.row.getField(column: self.string(for: key)).int()
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        Int8(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        Int16(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        Int32(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        Int64(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        UInt(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        UInt8(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        UInt16(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        UInt32(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        UInt64(try self.row.getField(column: self.string(for: key)).int())
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {

        if type == UUID.self {
            return try self.row.getField(column: self.string(for: key)).uuid() as! T
        } else if type == Date.self {
            return try self.row.getField(column: self.string(for: key)).date() as! T
        } else if type == JSONData.self {
            let field = try self.row.getField(column: self.string(for: key))
            return try JSONData(data: field.json()) as! T
        } else if type is AnyBelongsTo.Type {
            let field = try self.row.getField(column: self.string(for: key, includeIdSuffix: true))
            return try T(from: DatabaseFieldDecoder(field: field))
        } else if type is AnyHas.Type {
            // Special case the `AnyHas` to decode the coding key.
            let field = DatabaseField(column: "key", value: .string(key.stringValue))
            return try T(from: DatabaseFieldDecoder(field: field))
        } else if type is ModelEnum.Type {
            let field = try self.row.getField(column: self.string(for: key))
            return try T(from: DatabaseFieldDecoder(field: field))
        } else {
            let field = try self.row.getField(column: self.string(for: key))
            return try M.jsonDecoder.decode(T.self, from: field.json())
        }
    }
    
    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type, forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw DatabaseCodingError("Nested decoding isn't supported.")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw DatabaseCodingError("Nested decoding isn't supported.")
    }
    
    func superDecoder() throws -> Decoder {
        throw DatabaseCodingError("Super decoding isn't supported.")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        throw DatabaseCodingError("Super decoding isn't supported.")
    }
    
    /// Returns the database column string for a `CodingKey` given
    /// this container's `keyMappingStrategy`.
    ///
    /// Keys to parent relationships are special cased to append
    /// `M.belongsToColumnSuffix` to the field name.
    ///
    /// - Parameter key: The `CodingKey` to map.
    /// - Parameter includeIdSuffix: Whether `M.belongsToColumnSuffix`
    ///   should be appended to `key.stringValue` _before_ being
    ///   mapped.
    /// - Returns: The column name that `key` is mapped to.
    private func string(for key: Key, includeIdSuffix: Bool = false) -> String {
        let value = key.stringValue + (includeIdSuffix ? M.belongsToColumnSuffix : "")
        return M.keyMappingStrategy.map(input: value)
    }
}
