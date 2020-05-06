import Foundation

/// Given a `Codable` swift object, what is the best way to abstract the database storing, loading, schema
/// creation, schema migration?

/// Put the storing and loading inside a custom `Decoder` & `Encoder`. IBM seems to do it here & here
/// https://github.com/IBM-Swift/Swift-Kuery-ORM/blob/master/Sources/SwiftKueryORM/DatabaseDecoder.swift
/// https://github.com/IBM-Swift/Swift-Kuery-ORM/blob/master/Sources/SwiftKueryORM/DatabaseEncoder.swift

struct SomeStruct: Codable {
    let immutableString: String = "Josh"
    var data: Data = Data()
    var string: String = "Sir"
    var uuid: UUID = UUID()
    var url: URL = URL(string: "https://www.postgresql.org/docs/9.5/datatype.html")!
    var int: Int = 26
    var int8: Int8 = 2
    var int32: Int32 = 4
    var int64: Int64 = 8
    var double: Double = 26.0
    var date: Date = Date()
    var bool: Bool = false
    var optional: String? = nil
    var json: SomeJSON = SomeJSON(value: "someValue", other: 5)
    var array: [String] = ["first", "second", "third"]
}

struct SomeJSON: Codable {
    let value: String
    let other: Int
}

public struct CodableTester {
    public init() {}
    
    public func run() {
        let obj = SomeStruct()
        
        // Get mapping of `CodingKey` to it's value
        do {
            try self.usingCustomEncoder(obj)
        } catch {
            print("Error using dict: \(error)")
        }
    }
    
    func usingDictionary<E: Encodable>(_ obj: E) throws {
        // Won't use, can't interpret types well (`Bool` casts as `Int`, `Double`, and `Bool`) & it'll be
        // worse performance than using a custom encoder anyways (have to encode then decode into dict).
    }
    
    func usingCustomEncoder<E: Encodable>(_ obj: E) throws {
        let encoder = DatabaseEncoder()
        _ = try encoder.encode(obj, dateEncodingStrategy: .iso8601)
    }
}

struct DatabaseEncodingError: Error {
    let message: String
}

/// Class used to construct a dictionary [String: Any] from a Model
open class DatabaseEncoder {
    private var databaseEncoder = _DatabaseEncoder()

    /// Encode a Encodable type to a dictionary [String: Any]
    open func encode<T: Encodable>(_ value: T, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy) throws -> [String: Any] {
        databaseEncoder.dateEncodingStrategy = dateEncodingStrategy
        try value.encode(to: databaseEncoder)
        return databaseEncoder.values
    }
}

fileprivate class _DatabaseEncoder: Encoder {
    public var codingPath = [CodingKey]()

    public var values: [String: Any] = [:]

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
    var encoder: _DatabaseEncoder

    var codingPath = [CodingKey]()

    public mutating func encodeNil(forKey key: Key) throws {
        print("Got nil for \(key.stringValue).")
    }

    public mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        if let dataValue = value as? Data {
            print("Got data for \(key.stringValue).")
            encoder.values[key.stringValue] = dataValue.base64EncodedString()
        } else if let urlValue = value as? URL {
            print("Got url for \(key.stringValue).")
            encoder.values[key.stringValue] = urlValue.absoluteString
        } else if let uuidValue = value as? UUID {
            print("Got uuid for \(key.stringValue).")
            encoder.values[key.stringValue] = uuidValue.uuidString
        } else if let dateValue = value as? Date {
            print("Got date for \(key.stringValue).")
            encoder.values[key.stringValue] = dateValue.timeIntervalSinceReferenceDate
        } else if value is [Any] {
            print("Got array for \(key.stringValue).")
//            throw DatabaseEncodingError(message: "Encoding an array is not currently supported")
        } else if value is [AnyHashable: Any] {
            print("Got dict for \(key.stringValue).")
//            throw DatabaseEncodingError(message: "Encoding a dictionary is not currently supported")
        } else if let value = value as? Int {
            print("Got int for \(key.stringValue).")
        } else if let value = value as? Double {
            print("Got double for \(key.stringValue).")
        } else if let value = value as? Bool {
            print("Got bool for \(key.stringValue).")
        } else if let value = value as? String {
            print("Got string for \(key.stringValue).")
        } else {
            print("Got other type for \(key.stringValue).")
            encoder.values[key.stringValue] = value
        }
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return encoder.container(keyedBy: keyType)
    }

    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return encoder.unkeyedContainer()
    }

    public mutating func superEncoder() -> Encoder {
        return _DatabaseEncoder()
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return _DatabaseEncoder()
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
        // TODO when encoding Arrays ( not supported for now )
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
