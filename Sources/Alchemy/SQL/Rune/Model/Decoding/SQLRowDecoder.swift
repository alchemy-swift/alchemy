import Foundation

/// Decoder for decoding `Model` types from an `SQLRow`.
/// Properties of the `Decodable` type are matched to
/// columns with matching names (either the same
/// name or a specific name mapping based on
/// the supplied `keyMapping`).
struct SQLRowDecoder: SQLDecoder {
    /// The row that will be decoded out of.
    let row: SQLRow
    let keyMapping: DatabaseKeyMapping
    let jsonDecoder: JSONDecoder
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(KeyedContainer<Key>(row: row, decoder: self, keyMapping: keyMapping, jsonDecoder: jsonDecoder))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DatabaseCodingError("This shouldn't be called; top level is keyed.")
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DatabaseCodingError("This shouldn't be called; top level is keyed.")
    }
}

/// A `KeyedDecodingContainerProtocol` used to decode keys from a
/// `SQLRow`.
private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    /// The row to decode from.
    let row: SQLRow
    let decoder: SQLRowDecoder
    let keyMapping: DatabaseKeyMapping
    let jsonDecoder: JSONDecoder
    
    // MARK: KeyedDecodingContainerProtocol
    
    var codingPath: [CodingKey] = []
    var allKeys: [Key] = []
    
    func contains(_ key: Key) -> Bool {
        row.columns.contains(string(for: key))
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        let column = string(for: key)
        return try row.get(column) == .null
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        let column = string(for: key)
        return try row.get(column).bool(column)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        let column = string(for: key)
        return try row.get(column).string(column)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        let column = string(for: key)
        return try row.get(column).double(column)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        let column = string(for: key)
        return Float(try row.get(column).double(column))
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        let column = string(for: key)
        return try row.get(column).int(column)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        let column = string(for: key)
        return Int8(try row.get(column).int(column))
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        let column = string(for: key)
        return Int16(try row.get(column).int(column))
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        let column = string(for: key)
        return Int32(try row.get(column).int(column))
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        let column = string(for: key)
        return Int64(try row.get(column).int(column))
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        let column = string(for: key)
        return UInt(try row.get(column).int(column))
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        let column = string(for: key)
        return UInt8(try row.get(column).int(column))
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        let column = string(for: key)
        return UInt16(try row.get(column).int(column))
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        let column = string(for: key)
        return UInt32(try row.get(column).int(column))
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        let column = string(for: key)
        return UInt64(try row.get(column).int(column))
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        let column = string(for: key)
        if type == UUID.self {
            return try row.get(column).uuid(column) as! T
        } else if type == Date.self {
            return try row.get(column).date(column) as! T
        } else if type is AnyBelongsTo.Type {
            // need relationship mapping
            let belongsToColumn = string(for: key, includeIdSuffix: true)
            let value = row.columns.contains(belongsToColumn) ? try row.get(belongsToColumn) : nil
            return try (type as! AnyBelongsTo.Type).init(from: value) as! T
        } else if type is AnyHas.Type {
            return try T(from: decoder)
        } else if type is AnyModelEnum.Type {
            let field = try row.get(column)
            return try (type as! AnyModelEnum.Type).init(from: field) as! T
        }
        
        let field = try row.get(column)
        return try jsonDecoder.decode(T.self, from: field.json(column))
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
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
    /// this container's `keyMapping`.
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
        let value = key.stringValue + (includeIdSuffix ? "Id" : "")
        return keyMapping.map(input: value)
    }
}
