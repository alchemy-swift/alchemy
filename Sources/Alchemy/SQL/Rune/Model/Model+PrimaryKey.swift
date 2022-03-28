import Foundation

/// Represents a type that may be a primary key in a database. Out of
/// the box `UUID`, `String` and `Int` are supported but you can
/// easily support your own by conforming to this protocol.
public protocol PrimaryKey: Hashable, SQLValueConvertible, Codable {
    /// Initialize this value from an `SQLValue`.
    ///
    /// - Throws: If there is an error decoding this type from the
    ///   given database value.
    /// - Parameter field: The field with which this type should be
    ///   initialzed from.
    init(value: SQLValue) throws
}

extension UUID: PrimaryKey {
    public init(value: SQLValue) throws {
        self = try value.uuid()
    }
}

extension Int: PrimaryKey {
    public init(value: SQLValue) throws {
        self = try value.int()
    }
}

extension String: PrimaryKey {
    public init(value: SQLValue) throws {
        self = try value.string()
    }
}

extension Model {
    /// Initialize this model from a primary key. All other fields
    /// will be populated with dummy data. Useful for setting a
    /// relationship value based on just the primary key.
    ///
    /// - Parameter id: The primary key of this model.
    /// - Returns: An instance of `Self` with the given primary key.
    public static func pk(_ id: Self.Identifier) -> Self {
        var this = try! Self(from: DummyDecoder())
        this.id = id
        return this
    }
}

struct DummyDecoder: Decoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(Keyed())
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw RuneError("Unkeyed containers aren't supported yet.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw RuneError("Single value containers aren't supported yet, if you're using an enum, please conform it to `ModelEnum`.")
    }
}

private struct Keyed<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K
    var codingPath: [CodingKey] = []
    
    var allKeys: [K] = []
    
    func contains(_ key: K) -> Bool {
        true
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        false
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        true
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        "foo"
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        0
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        0
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        0
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        0
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        0
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        0
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        0
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        0
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        0
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        0
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        0
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        0
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        if let type = type as? AnyModelEnum.Type {
            return type.dummyValue as! T
        } else if type is AnyArray.Type {
            return [] as! T
        } else if type is AnyBelongsTo.Type {
            return try (type as! AnyBelongsTo.Type).init(from: nil) as! T
        } else if type is UUID.Type {
            return UUID() as! T
        } else if type is Date.Type {
            return Date() as! T
        }
        
        return try T(from: DummyDecoder())
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw RuneError("`DummyDecoder` doesn't support nested keyed containers yet.")
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        throw RuneError("`DummyDecoder` doesn't support nested unkeyed containers yet.")
    }
    
    func superDecoder() throws -> Decoder {
        throw RuneError("`DummyDecoder` doesn't support super decoding yet.")
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        throw RuneError("`DummyDecoder` doesn't support super decoding yet.")
    }
}

private protocol AnyBelongsTo {
    init(from: SQLValue?) throws
}
extension BelongsToRelationship: AnyBelongsTo {}

private protocol AnyArray {}
extension Array: AnyArray {}
