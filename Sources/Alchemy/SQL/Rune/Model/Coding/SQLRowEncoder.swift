import Foundation

/// Used for turning any `Encodable` into an ordered dictionary of columns to
/// `SQLValue`s based on its stored properties.
final class SQLRowEncoder: Encoder, SQLRowWriter {
    /// Used to decode keyed values from a Model.
    private struct _KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var writer: SQLRowWriter

        // MARK: KeyedEncodingContainerProtocol
        
        var codingPath = [CodingKey]()

        mutating func encodeNil(forKey key: Key) throws {
            writer.put(.null, at: key.stringValue)
        }

        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            guard let property = value as? ModelProperty else {
                // Assume anything else is JSON.
                try writer.put(json: value, at: key.stringValue)
                return
            }
            
            try property.store(key: key.stringValue, on: &writer)
        }
        
        mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            fatalError("Nested coding of `Model` not supported.")
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError("Nested coding of `Model` not supported.")
        }

        mutating func superEncoder() -> Encoder {
            fatalError("Superclass encoding of `Model` not supported.")
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError("Superclass encoding of `Model` not supported.")
        }
    }
    
    /// Used for keeping track of the database fields pulled off the
    /// object encoded to this encoder.
    private var readFields: [SQLField] = []
    
    /// The mapping strategy for associating `CodingKey`s on an object
    /// with column names in a database.
    let keyMapping: KeyMapping
    let jsonEncoder: JSONEncoder
    
    // MARK: Encoder
    
    var codingPath = [CodingKey]()
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Create with an associated `KeyMapping`.
    ///
    /// - Parameter mappingStrategy: The strategy for mapping `CodingKey` string
    ///   values to SQL columns.
    init(keyMapping: KeyMapping, jsonEncoder: JSONEncoder) {
        self.keyMapping = keyMapping
        self.jsonEncoder = jsonEncoder
    }
    
    subscript(column: String) -> SQLValue? {
        get { readFields.first(where: { $0.column == column })?.value }
        set { readFields.append(SQLField(column: keyMapping.encode(column), value: newValue ?? .null)) }
    }
    
    func put<E: Encodable>(json: E, at key: String) throws {
        let jsonData = try jsonEncoder.encode(json)
        self[key] = .json(jsonData)
    }
    
    /// Read and return the stored properties of an `Model` object.
    ///
    /// - Parameter value: The `Model` instance to read from.
    /// - Throws: A `DatabaseCodingError` if there is an error reading
    ///   fields from `value`.
    /// - Returns: An ordered dictionary of the model's columns and values.
    func sqlRow<E: Encodable>(for value: E) throws -> SQLRow {
        try value.encode(to: self)
        defer { readFields = [] }
        return SQLRow(fields: readFields)
    }
    
    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(_KeyedEncodingContainer<Key>(writer: self, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("`Model`s should never encode to an unkeyed container.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("`Model`s should never encode to a single value container.")
    }
}
