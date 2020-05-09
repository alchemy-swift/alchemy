import Foundation

/// Class used to construct a dictionary [String: Any] from a Model
open class DatabaseFieldReader {
    func readFields<E: Encodable>(of encodableValue: E) throws -> [DatabaseField] {
        let databaseEncoder = StoredPropertyReaderEncoder()
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

fileprivate struct _DatabaseKeyedEncodingContainer<K: CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    var encoder: StoredPropertyReaderEncoder

    var codingPath = [CodingKey]()

    public mutating func encodeNil(forKey key: Key) throws {
        /// Unfortunately auto generated codable functions are special cased to never call this...
        /// How can we update an object's field to nil?
        print("Got nil for \(key.stringValue).")
    }

    public mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        guard let theType = try self.propertyType(of: value) else {
            throw StoredPropertyError.unsupportedType(type: "\(type(of: value))", key: key.stringValue)
        }
        
        self.encoder.storedProperties.append(DatabaseField(column: key.stringValue, value: theType))
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
        return StoredPropertyReaderEncoder()
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return StoredPropertyReaderEncoder()
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
