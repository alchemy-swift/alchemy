import Foundation

/// Decoder for decoding `Model` types from an `SQLRow`.
/// Properties of the `Decodable` type are matched to
/// columns with matching names (either the same
/// name or a specific name mapping based on
/// the supplied `keyMapping`).
struct SQLRowDecoder: SQLDecoder {
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
            row.contains(string(for: key))
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            let column = string(for: key)
            return try row.require(column) == .null
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            let column = string(for: key)
            guard let thing = type as? ModelProperty.Type else {
                if type is AnyBelongsTo.Type {
                    // need relationship mapping
                    let belongsToColumn = string(for: key, includeIdSuffix: true)
                    let value = row.contains(belongsToColumn) ? try row.require(belongsToColumn) : nil
                    return try (type as! AnyBelongsTo.Type).init(from: value) as! T
                } else if type is AnyHas.Type {
                    return try T(from: decoder)
                } else if type is AnyModelEnum.Type {
                    let field = try row.require(column)
                    return try (type as! AnyModelEnum.Type).init(from: field) as! T
                } else {
                    print("NOT MODEL PROP! \(type)")
                    let field = try row.require(column)
                    return try jsonDecoder.decode(T.self, from: field.json(column))
                }
            }
            
            print("MODEL PROP!")
            let value = try row.require(column)
            let field = SQLField(column: column, value: value)
            return try thing.init(field: field) as! T
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

extension SQLRow {
    /// Get the `SQLValue` of a column from this row.
    ///
    /// - Parameter column: The column to get the value for.
    /// - Throws: A `DatabaseError` if the column does not exist on
    ///   this row.
    /// - Returns: The value at `column`.
    fileprivate func require(_ column: String) throws -> SQLValue {
        guard let value = self[column] else {
            throw DatabaseError.missingColumn(column)
        }
        
        return value
    }
}
