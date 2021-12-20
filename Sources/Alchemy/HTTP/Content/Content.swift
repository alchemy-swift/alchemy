import Foundation

/*
 Decoding individual fields from response / request bodies.
 1. Have a protocol `HasContent` for `Req/Res` & `Client.Req/Client.Res`.
 2. Have a cache for the decoded dictionary in extensions.
 3. Allow for single field access.
 4. For setting, have protocol `HasContentSettable` for `Res & Client.Req`
 */

/// A value inside HTTP content
@dynamicMemberLookup
enum Content {
    enum Query {
        case field(String)
        case index(Int)
        
        func apply(to content: Content) -> Content {
            switch self {
            case .field(let name):
                guard case .dict(let dict) = content else {
                    return .null
                }
                
                return (dict[name] ?? .null) ?? .null
            case .index(let index):
                guard case .array(let array) = content else {
                    return .null
                }
                
                return array[index] ?? .null
            }
        }
    }
    
    case array([Content?])
    case dict([String: Content?])
    case value(Encodable)
    case file(File)
    case null
    
    var string: String? { convertValue() }
    var int: Int? { convertValue() }
    var bool: Bool? { convertValue() }
    var double: Double? { convertValue() }
    var array: [Content?]? { convertValue() }
    var dictionary: [String: Content?]? { convertValue() }
    var isNull: Bool { self == nil }
    
    init(dict: [String: Encodable?]) {
        self = .dict(dict.mapValues(Content.init))
    }
    
    init(array: [Encodable?]) {
        self = .array(array.map(Content.init))
    }
    
    init(value: Encodable?) {
        switch value {
        case .some(let value):
            if let array = value as? [Encodable?] {
                self = Content(array: array)
            } else if let dict = value as? [String: Encodable?] {
                self = Content(dict: dict)
            } else {
                self = .value(value)
            }
        case .none:
            self = .null
        }
    }
    
    // MARK: - Subscripts
    
    subscript(index: Int) -> Content {
        Query.index(index).apply(to: self)
    }
    
    subscript(field: String) -> Content {
        Query.field(field).apply(to: self)
    }
    
    public subscript(dynamicMember member: String) -> Content {
        self[member]
    }
    
    subscript(operator: (Content, Content) -> Void) -> [Content?] {
        flatten()
    }
    
    static func *(lhs: Content, rhs: Content) {}
    
    static func ==(lhs: Content, rhs: Void?) -> Bool {
        if case .null = lhs {
            return true
        } else {
            return false
        }
    }
    
    private func convertValue<T>() -> T? {
        switch self {
        case .array(let array):
            return array as? T
        case .dict(let dict):
            return dict as? T
        case .value(let value):
            return value as? T
        case .file(let file):
            return file as? T
        case .null:
            return nil
        }
    }
    
    func flatten() -> [Content?] {
        switch self {
        case .null, .value, .file:
            return []
        case .dict(let dict):
            return Array(dict.values)
        case .array(let array):
            return array
                .compactMap { content -> [Content?]? in
                    if case .array(let array) = content {
                        return array
                    } else if case .dict = content {
                        return content.map { [$0] }
                    } else {
                        return nil
                    }
                }
                .flatMap { $0 }
        }
    }
    
    func decode<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        try D(from: GenericDecoder(delegate: self))
    }
}

extension Content: DecoderDelegate {
    
    private func require<T>(_ optional: T?, key: CodingKey?) throws -> T {
        try optional.unwrap(or: DecodingError.valueNotFound(T.self, .init(codingPath: [key].compactMap { $0 }, debugDescription: "Value wasn`t available.")))
    }
    
    func decodeString(for key: CodingKey?) throws -> String {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.string, key: key)
    }
    
    func decodeDouble(for key: CodingKey?) throws -> Double {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.double, key: key)
    }
    
    func decodeInt(for key: CodingKey?) throws -> Int {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.int, key: key)
    }
    
    func decodeBool(for key: CodingKey?) throws -> Bool {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.bool, key: key)
    }
    
    func decodeNil(for key: CodingKey?) -> Bool {
        let value = key.map { self[$0.stringValue] } ?? self
        return value == nil
    }
    
    func contains(key: CodingKey) -> Bool {
        dictionary?.keys.contains(key.stringValue) ?? false
    }
    
    func nested(for key: CodingKey) -> DecoderDelegate {
        self[key.stringValue]
    }
    
    func array(for key: CodingKey?) throws -> [DecoderDelegate] {
        let val = key.map { self[$0.stringValue] } ?? self
        guard let array = val.array else {
            throw DecodingError.dataCorrupted(.init(codingPath: [key].compactMap { $0 }, debugDescription: "Expected to find an array."))
        }
        
        return array.map { $0 ?? .null }
    }
}

protocol DecoderDelegate {
    // Values
    func decodeString(for key: CodingKey?) throws -> String
    func decodeDouble(for key: CodingKey?) throws -> Double
    func decodeInt(for key: CodingKey?) throws -> Int
    func decodeBool(for key: CodingKey?) throws -> Bool
    func decodeNil(for key: CodingKey?) -> Bool
    
    // Contains
    func contains(key: CodingKey) -> Bool
    
    // Array / Nested
    func nested(for key: CodingKey) throws -> DecoderDelegate
    func array(for key: CodingKey?) throws -> [DecoderDelegate]
}

extension DecoderDelegate {
    func _decode<T: Decodable>(_ type: T.Type = T.self, for key: CodingKey? = nil) throws -> T {
        var value: Any? = nil
        
        if T.self is Int.Type {
            value = try decodeInt(for: key)
        } else if T.self is String.Type {
            value = try decodeString(for: key)
        } else if T.self is Bool.Type {
            value = try decodeBool(for: key)
        } else if T.self is Double.Type {
            value = try decodeDouble(for: key)
        } else if T.self is Float.Type {
            value = Float(try decodeDouble(for: key))
        } else if T.self is Int8.Type {
            value = Int8(try decodeInt(for: key))
        } else if T.self is Int16.Type {
            value = Int16(try decodeInt(for: key))
        } else if T.self is Int32.Type {
            value = Int32(try decodeInt(for: key))
        } else if T.self is Int64.Type {
            value = Int64(try decodeInt(for: key))
        } else if T.self is UInt.Type {
            value = UInt(try decodeInt(for: key))
        } else if T.self is UInt8.Type {
            value = UInt8(try decodeInt(for: key))
        } else if T.self is UInt16.Type {
            value = UInt16(try decodeInt(for: key))
        } else if T.self is UInt32.Type {
            value = UInt32(try decodeInt(for: key))
        } else if T.self is UInt64.Type {
            value = UInt64(try decodeInt(for: key))
        } else {
            return try T(from: GenericDecoder(delegate: self))
        }
        
        guard let t = value as? T else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [key].compactMap { $0 },
                    debugDescription: "Unable to decode value of type \(T.self)."))
        }
        
        return t
    }
}

struct GenericDecoder: Decoder {
    var delegate: DecoderDelegate
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(Keyed(delegate: delegate))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        Unkeyed(delegate: try delegate.array(for: nil))
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        Single(delegate: delegate)
    }
}

extension GenericDecoder {
    struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let delegate: DecoderDelegate
        let codingPath: [CodingKey] = []
        let allKeys: [Key] = []
        
        func contains(_ key: Key) -> Bool {
            delegate.contains(key: key)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            delegate.decodeNil(for: key)
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            try delegate._decode(type, for: key)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            KeyedDecodingContainer(Keyed<NestedKey>(delegate: try delegate.nested(for: key)))
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            Unkeyed(delegate: try delegate.array(for: key))
        }
        
        func superDecoder() throws -> Decoder { fatalError() }
        func superDecoder(forKey key: Key) throws -> Decoder { fatalError() }
    }
    
    struct Unkeyed: UnkeyedDecodingContainer {
        let delegate: [DecoderDelegate]
        let codingPath: [CodingKey] = []
        var count: Int? { delegate.count }
        var isAtEnd: Bool { currentIndex == count }
        var currentIndex: Int = 0
        
        mutating func decodeNil() throws -> Bool {
            defer { currentIndex += 1 }
            return delegate[currentIndex].decodeNil(for: nil)
        }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            defer { currentIndex += 1 }
            return try delegate[currentIndex]._decode(type)
        }
        
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            defer { currentIndex += 1 }
            return Unkeyed(delegate: try delegate[currentIndex].array(for: nil))
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            defer { currentIndex += 1 }
            return KeyedDecodingContainer(Keyed(delegate: delegate[currentIndex]))
        }
        
        func superDecoder() throws -> Decoder { fatalError() }
    }
    
    struct Single: SingleValueDecodingContainer {
        let delegate: DecoderDelegate
        let codingPath: [CodingKey] = []
        
        func decodeNil() -> Bool {
            delegate.decodeNil(for: nil)
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            try delegate._decode(type)
        }
    }
}

extension Array where Element == Optional<Content> {
    var string: [String?] { map { $0?.string } }
    var int: [Int?] { map { $0?.int } }
    var bool: [Bool?] { map { $0?.bool } }
    var double: [Double?] { map { $0?.double } }
    
    subscript(field: String) -> [Content?] {
        return map { content -> Content? in
            content.map { Content.Query.field(field).apply(to: $0) }
        }
    }
    
    subscript(dynamicMember member: String) -> [Content?] {
        self[member]
    }
}

extension Dictionary where Value == Optional<Content> {
    var string: [Key: String?] { mapValues { $0?.string } }
    var int: [Key: Int?] { mapValues { $0?.int } }
    var bool: [Key: Bool?] { mapValues { $0?.bool } }
    var double: [Key: Double?] { mapValues { $0?.double } }
}

extension Content {
    var description: String {
        createString(value: self)
    }
    
    func createString(value: Content?, tabs: String = "") -> String {
        var string = ""
        var tabs = tabs
        switch value {
        case .array(let array):
            tabs += "\t"
            if array.isEmpty {
                string.append("[]")
            } else {
                string.append("[\n")
                for (index, item) in array.enumerated() {
                    let comma = index == array.count - 1 ? "" : ","
                    string.append(tabs + createString(value: item, tabs: tabs) + "\(comma)\n")
                }
                tabs = String(tabs.dropLast(1))
                string.append("\(tabs)]")
            }
        case .value(let value):
            if let value = value as? String {
                string.append("\"\(value)\"")
            } else {
                string.append("\(value)")
            }
        case .file(let file):
            string.append("<\(file.name)>")
        case .dict(let dict):
            tabs += "\t"
            string.append("{\n")
            for (index, (key, item)) in dict.enumerated() {
                let comma = index == dict.count - 1 ? "" : ","
                string.append(tabs + "\"\(key)\": " + createString(value: item, tabs: tabs) + "\(comma)\n")
            }
            tabs = String(tabs.dropLast(1))
            string.append("\(tabs)}")
        case .null, .none:
            string.append("null")
        }
        
        return string
    }
}

// Multipart // dict
// URL Form // dict
// JSON // dict

// Nesting JSON, URLForm, not multipart?
