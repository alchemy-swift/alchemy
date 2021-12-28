struct GenericDecoder: Decoder {
    struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let delegate: DecoderDelegate
        let codingPath: [CodingKey] = []
        var allKeys: [Key] { delegate.allKeys.compactMap { Key(stringValue: $0) } }
        
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
            KeyedDecodingContainer(Keyed<NestedKey>(delegate: try delegate.map(for: key)))
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            Unkeyed(delegate: try delegate.array(for: key))
        }
        
        func superDecoder() throws -> Decoder {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Super Decoder isn't supported."))
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Super Decoder isn't supported."))
        }
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
        
        func superDecoder() throws -> Decoder {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Super Decoder isn't supported."))
        }
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
    
    // MARK: Decoder
    
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

struct GenericCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
