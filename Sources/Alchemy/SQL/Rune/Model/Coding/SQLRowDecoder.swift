import Foundation

/// Decoder for decoding `Model` types from an `SQLRow`.
/// Properties of the `Decodable` type are matched to
/// columns with matching names (either the same
/// name or a specific name mapping based on
/// the supplied `keyMapping`).
struct SQLRowDecoder: Decoder, SQLRowReader {
    /// A `KeyedDecodingContainerProtocol` used to decode keys from a
    /// `SQLRow`.
    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let reader: SQLRowReader
        
        // MARK: KeyedDecodingContainerProtocol
        
        var codingPath: [CodingKey] = []
        var allKeys: [Key] = []
        
        func contains(_ key: Key) -> Bool {
            reader.contains(key.stringValue)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            try reader.require(key.stringValue) == .null
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            guard let thing = type as? ModelProperty.Type else {
                // Assume other types are JSON.
                return try reader.requireJSON(key.stringValue)
            }
            
            return try thing.init(key: key.stringValue, on: reader) as! T
        }
        
        func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
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
    }
    
    /// The row that will be decoded out of.
    let row: SQLRow
    let keyMapping: DatabaseKeyMapping
    let jsonDecoder: JSONDecoder
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(KeyedContainer<Key>(reader: self))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DatabaseCodingError("This shouldn't be called; top level is keyed.")
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DatabaseCodingError("This shouldn't be called; top level is keyed.")
    }
    
    // MARK: SQLRowReader
    
    func requireJSON<D: Decodable>(_ key: String) throws -> D {
        let key = keyMapping.map(input: key)
        return try jsonDecoder.decode(D.self, from: row.require(key).json(key))
    }
    
    func require(_ key: String) throws -> SQLValue {
        try row.require(keyMapping.map(input: key))
    }
    
    func contains(_ column: String) -> Bool {
        row[keyMapping.map(input: column)] != nil
    }
    
    subscript(_ index: Int) -> SQLValue {
        row[index]
    }
    
    subscript(_ column: String) -> SQLValue? {
        row[keyMapping.map(input: column)]
    }
}
