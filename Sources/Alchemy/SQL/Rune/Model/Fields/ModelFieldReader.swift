import Foundation

/// Used so `Relationship` types can know not to encode themselves to
/// a `SQLEncoder`.
protocol SQLEncoder: Encoder {}

/// Used for turning any `Model` into an ordered dictionary of columns to
/// `SQLValue`s based on its stored properties.
final class ModelFieldReader<M: Model>: SQLEncoder {
    /// Used for keeping track of the database fields pulled off the
    /// object encoded to this encoder.
    fileprivate var readFields: [(column: String, value: SQLValue)] = []
    
    /// The mapping strategy for associating `CodingKey`s on an object
    /// with column names in a database.
    fileprivate let mappingStrategy: DatabaseKeyMapping
    
    // MARK: Encoder
    
    var codingPath = [CodingKey]()
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Create with an associated `DatabasekeyMapping`.
    ///
    /// - Parameter mappingStrategy: The strategy for mapping `CodingKey` string
    ///   values to SQL columns.
    init(_ mappingStrategy: DatabaseKeyMapping) {
        self.mappingStrategy = mappingStrategy
    }
    
    /// Read and return the stored properties of an `Model` object.
    ///
    /// - Parameter value: The `Model` instance to read from.
    /// - Throws: A `DatabaseCodingError` if there is an error reading
    ///   fields from `value`.
    /// - Returns: An ordered dictionary of the model's columns and values.
    func getFields(of model: M) throws -> [SQLField] {
        try model.encode(to: self)
        defer { readFields = [] }
        return readFields.map { SQLField(column: $0.column, value: $0.value) }
    }

    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(_KeyedEncodingContainer<M, Key>(encoder: self, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("`Model`s should never encode to an unkeyed container.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("`Model`s should never encode to a single value container.")
    }
}

private struct _KeyedEncodingContainer<M: Model, Key: CodingKey>: KeyedEncodingContainerProtocol, ModelValueReader {
    var encoder: ModelFieldReader<M>

    // MARK: KeyedEncodingContainerProtocol
    
    var codingPath = [CodingKey]()

    mutating func encodeNil(forKey key: Key) throws {
        let keyString = encoder.mappingStrategy.map(input: key.stringValue)
        encoder.readFields.append((keyString, SQLValue.null))
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        guard !(value is AnyBelongsTo) else {
            let keyString = encoder.mappingStrategy.map(input: key.stringValue + "Id")
            if let idValue = (value as? AnyBelongsTo)?.idValue {
                encoder.readFields.append((keyString, idValue))
            }
            
            return
        }
        
        guard !(value is AnyHas) else { return }
        
        let keyString = encoder.mappingStrategy.map(input: key.stringValue)
        guard let convertible = value as? SQLValueConvertible else {
            // Assume anything else is JSON.
            let jsonData = try M.jsonEncoder.encode(value)
            encoder.readFields.append((column: keyString, value: .json(jsonData)))
            return
        }
        
        encoder.readFields.append((column: keyString, value: convertible.sqlValue))
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
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

/// Used for passing along the type of the `Model` various containers
/// are working with so that the `Model`'s custom encoders can be
/// used.
private protocol ModelValueReader {
    /// The `Model` type this field reader is reading from.
    associatedtype M: Model
}
