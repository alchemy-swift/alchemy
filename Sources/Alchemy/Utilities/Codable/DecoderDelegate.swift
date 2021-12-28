protocol DecoderDelegate {
    // Values
    func decodeString(for key: CodingKey?) throws -> String
    func decodeDouble(for key: CodingKey?) throws -> Double
    func decodeInt(for key: CodingKey?) throws -> Int
    func decodeBool(for key: CodingKey?) throws -> Bool
    func decodeNil(for key: CodingKey?) -> Bool
    
    // Contains
    func contains(key: CodingKey) -> Bool
    var allKeys: [String] { get }
    
    // Array / Map
    func map(for key: CodingKey) throws -> DecoderDelegate
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
            return try T(from: GenericDecoder(delegate: key.map { try map(for: $0) } ?? self))
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
