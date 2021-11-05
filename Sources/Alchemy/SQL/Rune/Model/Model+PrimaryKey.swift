import Foundation

/// Represents a type that may be a primary key in a database. Out of
/// the box `UUID`, `String` and `Int` are supported but you can
/// easily support your own by conforming to this protocol.
public protocol PrimaryKey: Hashable, SQLValueConvertible, Codable {
    /// Initialize this value from a `DatabaseField`.
    ///
    /// - Throws: If there is an error decoding this type from the
    ///   given database value.
    /// - Parameter field: The field with which this type should be
    ///   initialzed from.
    init(field: DatabaseField) throws
}

extension UUID: PrimaryKey {
    public init(field: DatabaseField) throws {
        self = try field.uuid()
    }
}

extension Int: PrimaryKey {
    public init(field: DatabaseField) throws {
        self = try field.int()
    }
}

extension String: PrimaryKey {
    public init(field: DatabaseField) throws {
        self = try field.string()
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

private struct DummyDecoder: Decoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(Keyed())
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        Unkeyed()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValue()
    }
}

private struct SingleValue: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    
    func decodeNil() -> Bool {
        false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        true
    }
    
    func decode(_ type: String.Type) throws -> String {
        "foo"
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        0
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        0
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        0
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        0
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        0
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        0
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        0
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        0
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        0
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        0
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        0
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        0
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try T(from: DummyDecoder())
    }
}

private struct Unkeyed: UnkeyedDecodingContainer {
    var codingPath: [CodingKey] = []
    
    var count: Int? = nil
    
    var isAtEnd: Bool = false
    
    var currentIndex: Int = 0
    
    mutating func decodeNil() throws -> Bool {
        false
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        true
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        "foo"
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        0
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        0
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        0
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        0
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        0
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        0
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        0
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        0
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        0
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        0
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        0
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        0
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try T(from: DummyDecoder())
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw RuneError("`DummyDecoder` doesn't support nested keyed containers yet.")
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw RuneError("`DummyDecoder` doesn't support nested unkeyed containers yet.")
    }
    
    mutating func superDecoder() throws -> Decoder {
        throw RuneError("`DummyDecoder` doesn't support super decoders yet.")
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
        if type is AnyModelEnum.Type {
            return (type as! AnyModelEnum.Type).defaultCase as! T
        } else if type is AnyArray.Type {
            return [] as! T
        } else {
            return try T(from: DummyDecoder())
        }
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

private protocol AnyArray {}
extension Array: AnyArray {}
