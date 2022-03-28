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
                // Store every other type as JSON.
                let field = try row.require(column)
                return try jsonDecoder.decode(T.self, from: field.json(column))
            }
            
            let view = SQLRowView(row: row, keyMapping: keyMapping)
            return try thing.init(key: key.stringValue, on: view) as! T
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
        
        private func string(for key: Key) -> String {
            keyMapping.map(input: key.stringValue)
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
