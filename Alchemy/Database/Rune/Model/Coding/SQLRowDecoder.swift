struct SQLRowDecoder: Decoder {
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
            throw DatabaseError("Nested decoding isn't supported.")
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            throw DatabaseError("Nested decoding isn't supported.")
        }
        
        func superDecoder() throws -> Decoder {
            throw DatabaseError("Super decoding isn't supported.")
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            throw DatabaseError("Super decoding isn't supported.")
        }
    }

    private struct SingleContainer: SingleValueDecodingContainer {
        let reader: SQLRowReader
        let column: String
        var codingPath: [CodingKey] = []

        func decodeNil() -> Bool {
            guard let value = try? reader.require(column) else {
                return false
            }

            return value == .null
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            guard let thing = type as? ModelProperty.Type else {
                // Assume other types are JSON.
                return try reader.requireJSON(column)
            }

            return try thing.init(key: column, on: reader) as! T
        }
    }

    /// The row that will be decoded out of.
    let reader: SQLRowReader

    init(row: SQLRow, keyMapping: KeyMapping, jsonDecoder: JSONDecoder) {
        self.reader = SQLRowReader(row: row, keyMapping: keyMapping, jsonDecoder: jsonDecoder)
    }

    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(KeyedContainer<Key>(reader: reader))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DatabaseError("This should not be called; top level is keyed.")
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        guard let firstColumn = reader.row.fields.elements.first?.key else {
            throw DatabaseError("SQLRow had no fields to decode a value from.")
        }

        return SingleContainer(reader: reader, column: firstColumn)
    }
}
