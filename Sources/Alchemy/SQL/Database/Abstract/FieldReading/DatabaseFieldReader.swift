import Foundation

/// Used for turning any `DatabaseCodable` into an array of `DatabaseField`s (column/value
/// combinations) based on its stored properties.
final class DatabaseFieldReader: Encoder {
    /// Used for keeping track of the database fields pulled off the object encoded to this encoder.
    fileprivate var readFields: [DatabaseField] = []
    
    /// The mapping strategy for associating `CodingKey`s on an object with column names in a
    /// database.
    fileprivate let mappingStrategy: DatabaseKeyMappingStrategy
    
    // MARK: Encoder
    
    var codingPath = [CodingKey]()
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Create with an associated `DatabaseKeyMappingStrategy`.
    ///
    /// - Parameter mappingStrategy: the strategy for mapping `CodingKey` string values to the
    ///                              `column`s of `DatabaseField`s.
    init(_ mappingStrategy: DatabaseKeyMappingStrategy) {
        self.mappingStrategy = mappingStrategy
    }
    
    /// Read and return the stored properties of an `DatabaseCodable` object as a `[DatabaseField]`.
    ///
    /// - Parameter value: the `DatabaseCodable` instance to read from.
    /// - Throws: a `DatabaseCodingError` if there is an error reading fields from `value`.
    /// - Returns: an array of `DatabaseField`s representing the properties of `value`.
    func getFields<D: DatabaseCodable>(of value: D) throws -> [DatabaseField] {
        try value.encode(to: self)
        let toReturn = self.readFields
        self.readFields = []
        return toReturn
    }

    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = _KeyedEncodingContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("`DatabaseCodable`s should never encode to an unkeyed container.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("`DatabaseCodable`s should never encode to a single value container.")
    }
}

/// Encoder helper for pulling out `DatabaseField`s from any fields that encode to a
/// `SingleValueEncodingContainer`.
private struct _SingleValueEncoder: Encoder {
    /// The database column to which a value encoded here should map to.
    let column: String
    
    /// The `DatabaseFieldReader` that is being used to read the stored properties of an object.
    /// Need to pass it around so various containers can add to it's `readFields`.
    let encoder: DatabaseFieldReader
    
    // MARK: Encoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(
        keyedBy type: Key.Type
    ) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        KeyedEncodingContainer(
            _KeyedEncodingContainer<Key>(encoder: self.encoder, codingPath: codingPath)
        )
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Arrays aren't supported by `DatabaseCodable`.")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        _SingleValueEncodingContainer(column: self.column, encoder: self.encoder)
    }
}

private struct _SingleValueEncodingContainer: SingleValueEncodingContainer {
    /// The database column to which a value encoded to this container should map to.
    let column: String
    
    /// The `DatabaseFieldReader` that is being used to read the stored properties of an object.
    /// Need to pass it around so various containers can add to it's `readFields`.
    var encoder: DatabaseFieldReader
    
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
        if let value = try databaseValue(of: value) {
            self.encoder.readFields.append(DatabaseField(column: self.column, value: value))
        } else {
            throw DatabaseCodingError("Error encoding type `\(type(of: T.self))` into single value "
                                        + "container.")
        }
    }
}

private struct _KeyedEncodingContainer<Key: CodingKey> : KeyedEncodingContainerProtocol {
    var encoder: DatabaseFieldReader

    // MARK: KeyedEncodingContainerProtocol
    
    var codingPath = [CodingKey]()

    mutating func encodeNil(forKey key: Key) throws {
        /// Unfortunately auto generated codable functions are special cased to never call this...
        /// How can we update an object's field to nil?
        print("Got nil for \(self.encoder.mappingStrategy.map(input: key.stringValue)).")
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let keyString = self.encoder.mappingStrategy.map(input: key.stringValue)
        if let theType = try databaseValue(of: value) {
            self.encoder.readFields.append(DatabaseField(column: keyString, value: theType))
        } else if value is AnyBelongsTo {
            // Special case parent relationships to append a `_id` after the property name.
            try value.encode(to: _SingleValueEncoder(column: keyString + "_id", encoder: self.encoder))
        } else if value is AnyHas {
            // do nothing
        } else {
            try value.encode(to: _SingleValueEncoder(column: keyString, encoder: self.encoder))
        }
    }
    
    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type, forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        fatalError("Nested coding of `DatabaseCodable` not supported.")
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("Nested coding of `DatabaseCodable` not supported.")
    }

    mutating func superEncoder() -> Encoder {
        fatalError("Superclass encoding of `DatabaseCodable` not supported.")
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Superclass encoding of `DatabaseCodable` not supported.")
    }
}

/// Returns a `DatabaseValue` for an `Encodable` value. If the value isn't a supported
/// `DatabaseValue`, it is encoded to `Data` returned as `.json(Data)`. This is special cased to
/// return nil if the value is a Rune `Relationship`.
///
/// Pretty ugly, is there a cleaner way of doing this?
///
/// - Parameter value: the value to map to a `DatabaseValue`.
/// - Throws: an `EncodingError` if there is an issue encoding a value perceived to be JSON.
/// - Returns: a `DatabaseValue` representing `value` or `nil` if value is a Rune Relationship.
private func databaseValue<E: Encodable>(of value: E) throws -> DatabaseValue? {
    if let value = value as? UUID {
        return .uuid(value)
    } else if let value = value as? Date {
        return .date(value)
    } else if let value = value as? Int {
        return .int(value)
    } else if let value = value as? Double {
        return .double(value)
    } else if let value = value as? Bool {
        return .bool(value)
    } else if let value = value as? String {
        return .string(value)
    } else if let _ = value as? AnyHas {
        return nil
    } else if let _ = value as? AnyBelongsTo {
        return nil
    } else {
        // Assume anything else is JSON.
        let jsonData = try JSONEncoder().encode(value)
        return .json(jsonData)
    }
}
