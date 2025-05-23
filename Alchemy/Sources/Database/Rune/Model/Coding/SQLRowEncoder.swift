import Foundation

final class SQLRowEncoder: Encoder {
    /// Used to decode keyed values from a Model.
    private struct _KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: SQLRowEncoder
        var codingPath = [CodingKey]()

        mutating func encodeNil(forKey key: Key) throws {
            encoder.writer.put(sql: .null, at: key.stringValue)
        }

        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            guard let property = value as? ModelProperty else {
                // Assume anything else is JSON.
                try encoder.writer.put(json: value, at: key.stringValue)
                return
            }
            
            try property.store(key: key.stringValue, on: &encoder.writer)
        }
        
        mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            preconditionFailure("Nested coding of `Model` not supported.")
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            preconditionFailure("Nested coding of `Model` not supported.")
        }

        mutating func superEncoder() -> Encoder {
            preconditionFailure("Superclass encoding of `Model` not supported.")
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            preconditionFailure("Superclass encoding of `Model` not supported.")
        }
    }
    
    /// Used for keeping track of the database fields pulled off the
    /// object encoded to this encoder.
    private var writer: SQLRowWriter

    /// The mapping strategy for associating `CodingKey`s on an object
    /// with column names in a database.
    var codingPath = [CodingKey]()
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Create with an associated `KeyMapping`.
    ///
    /// - Parameter mappingStrategy: The strategy for mapping `CodingKey` string
    ///   values to SQL columns.
    init(keyMapping: KeyMapping, jsonEncoder: JSONEncoder) {
        self.writer = SQLRowWriter(keyMapping: keyMapping, jsonEncoder: jsonEncoder)
    }

    /// Read and return the stored properties of an `Model` object.
    ///
    /// - Parameter value: The `Model` instance to read from.
    /// - Throws: A `DatabaseError` if there is an error reading
    ///   fields from `value`.
    /// - Returns: An ordered dictionary of the model's columns and values.
    func fields<E: Encodable>(for value: E) throws -> SQLFields {
        try value.encode(to: self)
        defer { writer.fields = [:] }
        return writer.fields
    }

    // MARK: Encoder

    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(_KeyedEncodingContainer<Key>(encoder: self, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        preconditionFailure("`Model`s should never encode to an unkeyed container.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        preconditionFailure("`Model`s should never encode to a single value container.")
    }
}
