import Foundation

/// Used so `Relationship` types can know not to encode themselves to
/// a `ModelEncoder`.
protocol ModelEncoder: Encoder {}

/// Used for turning any `Model` into an array of `DatabaseField`s
/// (column/value combinations) based on its stored properties.
final class ModelFieldReader<M: Model>: ModelEncoder {
    /// Used for keeping track of the database fields pulled off the
    /// object encoded to this encoder.
    fileprivate var readFields: [DatabaseField] = []
    
    /// The mapping strategy for associating `CodingKey`s on an object
    /// with column names in a database.
    fileprivate let mappingStrategy: DatabaseKeyMapping
    
    // MARK: Encoder
    
    var codingPath = [CodingKey]()
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Create with an associated `DatabaseKeyMappingStrategy`.
    ///
    /// - Parameter mappingStrategy: The strategy for mapping
    /// `CodingKey` string values to the `column`s of
    /// `DatabaseField`s.
    init(_ mappingStrategy: DatabaseKeyMapping) {
        self.mappingStrategy = mappingStrategy
    }
    
    /// Read and return the stored properties of an `Model` object as
    /// a `[DatabaseField]`.
    ///
    /// - Parameter value: The `Model` instance to read from.
    /// - Throws: A `DatabaseCodingError` if there is an error reading
    ///   fields from `value`.
    /// - Returns: An array of `DatabaseField`s representing the
    ///   properties of `value`.
    func getFields(of value: M) throws -> [DatabaseField] {
        try value.encode(to: self)
        let toReturn = self.readFields
        self.readFields = []
        return toReturn
    }

    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = _KeyedEncodingContainer<M, Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("`Model`s should never encode to an unkeyed container.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("`Model`s should never encode to a single value container.")
    }
}

/// Encoder helper for pulling out `DatabaseField`s from any fields
/// that encode to a `SingleValueEncodingContainer`.
private struct _SingleValueEncoder<M: Model>: ModelEncoder {
    /// The database column to which a value encoded here should map
    /// to.
    let column: String
    
    /// The `DatabaseFieldReader` that is being used to read the
    /// stored properties of an object. Need to pass it around
    /// so various containers can add to it's `readFields`.
    let encoder: ModelFieldReader<M>
    
    // MARK: Encoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(
        keyedBy type: Key.Type
    ) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        KeyedEncodingContainer(
            _KeyedEncodingContainer<M, Key>(encoder: self.encoder, codingPath: codingPath)
        )
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Arrays aren't supported by `Model`.")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        _SingleValueEncodingContainer<M>(column: self.column, encoder: self.encoder)
    }
}

private struct _SingleValueEncodingContainer<
    M: Model
>: SingleValueEncodingContainer, ModelValueReader {
    /// The database column to which a value encoded to this container
    /// should map to.
    let column: String
    
    /// The `DatabaseFieldReader` that is being used to read the
    /// stored properties of an object. Need to pass it around
    /// so various containers can add to it's `readFields`.
    var encoder: ModelFieldReader<M>
    
    // MARK: SingleValueEncodingContainer
    
    var codingPath: [CodingKey] = []
    
    mutating func encodeNil() throws {
        // Can't infer the type so not much we can do here.
    }
    
    mutating func encode(_ value: Bool) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .bool(value)))
    }
    
    mutating func encode(_ value: String) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .string(value)))
    }
    
    mutating func encode(_ value: Double) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .double(value)))
    }
    
    mutating func encode(_ value: Float) throws {
        let field = DatabaseField(column: self.column, value: .double(Double(value)))
        self.encoder.readFields.append(field)
    }
    
    mutating func encode(_ value: Int) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(value)))
    }
    
    mutating func encode(_ value: Int8) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: Int16) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: Int32) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: Int64) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt8) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt16) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt32) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt64) throws {
        self.encoder.readFields.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        if let value = try self.databaseValue(of: value) {
            self.encoder.readFields.append(DatabaseField(column: self.column, value: value))
        } else {
            throw DatabaseCodingError("Error encoding type `\(type(of: T.self))` into single value "
                                        + "container.")
        }
    }
}

private struct _KeyedEncodingContainer<
    M: Model,
    Key: CodingKey
>: KeyedEncodingContainerProtocol, ModelValueReader {
    var encoder: ModelFieldReader<M>

    // MARK: KeyedEncodingContainerProtocol
    
    var codingPath = [CodingKey]()

    mutating func encodeNil(forKey key: Key) throws {
        print("Got nil for \(self.encoder.mappingStrategy.map(input: key.stringValue)).")
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        if let theType = try self.databaseValue(of: value) {
            let keyString = self.encoder.mappingStrategy.map(input: key.stringValue)
            self.encoder.readFields.append(DatabaseField(column: keyString, value: theType))
        } else if value is AnyBelongsTo {
            // Special case parent relationships to append
            // `M.belongsToColumnSuffix` to the property name.
            let keyString = self.encoder.mappingStrategy
                .map(input: key.stringValue + M.belongsToColumnSuffix)
            try value.encode(
                to: _SingleValueEncoder<M>(column: keyString, encoder: self.encoder)
            )
        } else {
            let keyString = self.encoder.mappingStrategy.map(input: key.stringValue)
            try value.encode(to: _SingleValueEncoder<M>(column: keyString, encoder: self.encoder))
        }
    }
    
    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type, forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
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

extension ModelValueReader {
    /// Returns a `DatabaseValue` for a `Model` value. If the value
    /// isn't a supported `DatabaseValue`, it is encoded to `Data`
    /// returned as `.json(Data)`. This is special cased to
    /// return nil if the value is a Rune relationship.
    ///
    /// - Parameter value: The value to map to a `DatabaseValue`.
    /// - Throws: An `EncodingError` if there is an issue encoding a
    ///   value perceived to be JSON.
    /// - Returns: A `DatabaseValue` representing `value` or `nil` if
    ///   value is a Rune relationship.
    fileprivate func databaseValue<E: Encodable>(of value: E) throws -> DatabaseValue? {
        if let value = value as? Parameter {
            return value.value
        } else if value is AnyBelongsTo || value is AnyHas {
            return nil
        } else {
            // Assume anything else is JSON.
            let jsonData = try M.jsonEncoder.encode(value)
            return .json(jsonData)
        }
    }
}
