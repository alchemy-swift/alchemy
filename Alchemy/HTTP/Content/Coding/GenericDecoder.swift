struct GenericDecoder: Decoder {
    struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let delegate: GenericDecoderDelegate
        let codingPath: [CodingKey] = []
        var allKeys: [Key] { delegate.allKeys.compactMap { Key(stringValue: $0) } }
        
        func contains(_ key: Key) -> Bool {
            delegate.contains(key: key)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            delegate.decodeNil(for: key)
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            try delegate.decode(type, for: key)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            KeyedDecodingContainer(Keyed<NestedKey>(delegate: try delegate.dictionary(for: key)))
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
        let delegate: [GenericDecoderDelegate]
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
            return try delegate[currentIndex].decode(type)
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
        let delegate: GenericDecoderDelegate
        let codingPath: [CodingKey] = []
        
        func decodeNil() -> Bool {
            delegate.decodeNil(for: nil)
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            try delegate.decode(type)
        }
    }
    
    // MARK: Decoder
    
    var delegate: GenericDecoderDelegate
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

extension GenericDecoderDelegate {
    fileprivate func decode<T: Decodable>(_ type: T.Type = T.self, for key: CodingKey? = nil) throws -> T {
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
            return try T(from: GenericDecoder(delegate: key.map { try dictionary(for: $0) } ?? self))
        }

        guard let t = value as? T else {
            let context = DecodingError.Context(codingPath: [key].compactMap { $0 }, debugDescription: "Unable to decode value of type \(T.self).")
            throw DecodingError.dataCorrupted(context)
        }

        return t
    }
}
