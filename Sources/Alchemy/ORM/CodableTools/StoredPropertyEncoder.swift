import Foundation

/// Class used to construct a dictionary [String: Any] from a Model
open class DatabaseFieldReader {
    func readFields<D: DatabaseCodable>(of encodableValue: D) throws -> [DatabaseField] {
        let databaseEncoder = StoredPropertyReaderEncoder(D.keyMappingStrategy)
        try encodableValue.encode(to: databaseEncoder)
        return databaseEncoder.storedProperties
    }
}

enum StoredPropertyError: Error {
    case unsupportedType(type: String, key: String)
}

private class StoredPropertyReaderEncoder: Encoder {
    public var codingPath = [CodingKey]()

    public var storedProperties: [DatabaseField] = []

    public var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
    let mappingStrategy: DatabaseKeyMappingStrategy
    
    init(_ mappingStrategy: DatabaseKeyMappingStrategy) {
        self.mappingStrategy = mappingStrategy
    }

    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = _DatabaseKeyedEncodingContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _DatabaseEncodingContainer(encoder: self, codingPath: codingPath, count: 0)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return _DatabaseEncodingContainer(encoder: self, codingPath: codingPath, count: 0)
    }
}

private struct _SingleValueEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]

    let column: String
    let encoder: StoredPropertyReaderEncoder
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        KeyedEncodingContainer(_DatabaseKeyedEncodingContainer<Key>(encoder: self.encoder, codingPath: codingPath))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _DatabaseEncodingContainer(encoder: self, codingPath: codingPath, count: 0)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        _SingleValueEncodingContainer(column: self.column, encoder: self.encoder)
    }
}

private struct _SingleValueEncodingContainer: SingleValueEncodingContainer {
    var codingPath: [CodingKey] = []
    let column: String
    var encoder: StoredPropertyReaderEncoder?
    
    mutating func encodeNil() throws {
        // Can't infer the type so not much we can do here.
    }
    
    mutating func encode(_ value: Bool) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .bool(value)))
    }
    
    mutating func encode(_ value: String) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .string(value)))
    }
    
    mutating func encode(_ value: Double) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .double(value)))
    }
    
    mutating func encode(_ value: Float) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .double(Double(value))))
    }
    
    mutating func encode(_ value: Int) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(value)))
    }
    
    mutating func encode(_ value: Int8) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: Int16) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: Int32) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: Int64) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt8) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt16) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt32) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode(_ value: UInt64) throws {
        self.encoder?.storedProperties.append(DatabaseField(column: self.column, value: .int(Int(value))))
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        throw DatabaseDecodingError("Error encoding type `\(type(of: T.self))` into single value container.")
    }
}

private struct _DatabaseKeyedEncodingContainer<K: CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    var encoder: StoredPropertyReaderEncoder

    var codingPath = [CodingKey]()

    public mutating func encodeNil(forKey key: Key) throws {
        /// Unfortunately auto generated codable functions are special cased to never call this...
        /// How can we update an object's field to nil?
        print("Got nil for \(self.encoder.mappingStrategy.map(input: key.stringValue)).")
    }

    public mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let keyString = self.encoder.mappingStrategy.map(input: key.stringValue)
        if let theType = try self.propertyType(of: value) {
            self.encoder.storedProperties.append(DatabaseField(column: keyString, value: theType))
        } else {
            try value.encode(to: _SingleValueEncoder(column: keyString, encoder: self.encoder))
        }
    }
    
    private func propertyType<E: Encodable>(of value: E) throws -> DatabaseField.Value? {
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
        } else if let value = value as? DatabaseJSON {
            return .json(try value.toJSONData())
        } else {
            return nil
        }
    }
    
    func getArrayElement<A: Collection>(a: A) -> A.Element {
        fatalError()
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return encoder.container(keyedBy: keyType)
    }

    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return encoder.unkeyedContainer()
    }

    public mutating func superEncoder() -> Encoder {
        return StoredPropertyReaderEncoder(.useDefaultKeys)
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return StoredPropertyReaderEncoder(.useDefaultKeys)
    }
}

/// Default implenations of UnkeyedEncodingContainer and SingleValueEncodingContainer
/// Should never go into these containers. Types are checked in the TypeDecoder
fileprivate struct _DatabaseEncodingContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {

    var encoder: Encoder
    var codingPath = [CodingKey]()
    var count: Int = 0

    public mutating func encodeNil() throws {}

    public mutating func encode<T: Encodable>(_ value: T) {
        print("What the...")
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return encoder.container(keyedBy: keyType)
    }

    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return encoder.unkeyedContainer()
    }

    public mutating func superEncoder() -> Encoder {
        return encoder
    }

}
