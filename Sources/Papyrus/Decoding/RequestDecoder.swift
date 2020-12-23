typealias KeyMappingStrategy = (String) -> String

/// Decodes a `EndpointRequest` from a `HTTPRequest`.
struct HTTPRequestDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let request: DecodableRequest
    
    let keyMappingStrategy: KeyMappingStrategy
    
    init(request: DecodableRequest, keyMappingStrategy: @escaping KeyMappingStrategy) {
        self.request = request
        self.keyMappingStrategy = keyMappingStrategy
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedContainer(request: self.request, keyMappingStrategy: self.keyMappingStrategy))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        /// This is for arrays, which we currently support in other ways.
        throw PapyrusError("This shouldn't be called; top level is keyed.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw PapyrusError("This shouldn't be called; top level is keyed.")
    }
}

private struct HTTPParamDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let request: DecodableRequest
    let param: HTTPParameter
    let key: String
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        throw PapyrusError("`container` shouldn't be called; this is only for single values.")
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw PapyrusError("`unkeyedContainer` shouldn't be called; this is only for single values.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        HTTPRequestSingleValueDecodingContainer(request: self.request, parameter: self.param, key: self.key)
    }
}

private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    /// Used for debugging only I believe; ignoring for now.
    var codingPath: [CodingKey] = []
    
    /// From what I can tell this is only used in custom `decodes` (which we will explicitly say not to do
    /// since it will break a lot of database coding logic).
    ///
    /// Can't populate here since there is no way to match database column strings to the original coding key,
    /// without an inverse of the `DatabaseKeyMappingStrategy`.
    ///
    /// Consider coding key `userID` that when using snake case mapping gets mapped to `user_id`. We coudln't
    /// convert that back properly, since there would be no way to know if it was `userId` or `userID`.
    var allKeys: [Key] {
        []
    }
    
    let request: DecodableRequest
    let keyMappingStrategy: KeyMappingStrategy
    
    private func string(for key: Key) -> String {
        self.keyMappingStrategy(key.stringValue)
    }
    
    func contains(_ key: Key) -> Bool {
        fatalError("`contains` unsupported")
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        throw PapyrusError("`decodeNil` unsupported.")
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        throw PapyrusError("`bool` unsupported.")
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        throw PapyrusError("`string` unsupported.")
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        throw PapyrusError("`double` unsupported.")
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        throw PapyrusError("`float` unsupported.")
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        throw PapyrusError("`int` unsupported.")
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        throw PapyrusError("`int8` unsupported.")
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        throw PapyrusError("`int16` unsupported.")
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        throw PapyrusError("`int32` unsupported.")
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        throw PapyrusError("`int64` unsupported.")
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        throw PapyrusError("`uint` unsupported.")
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        throw PapyrusError("`uint8` unsupported.")
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        throw PapyrusError("`uint16` unsupported.")
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        throw PapyrusError("`uint32` unsupported.")
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        throw PapyrusError("`uint64` unsupported.")
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        if type is AnyHeader.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .header, key: key.stringValue))
        } else if type is AnyBody.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .body, key: key.stringValue))
        } else if type is AnyQuery.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .query, key: key.stringValue))
        } else if type is AnyPath.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .path, key: key.stringValue))
        } else {
            throw PapyrusError("`\(type)` unsupported.")
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw PapyrusError("This shouldn't be called? http nextedContainer")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw PapyrusError("This shouldn't be called? http nestedUnkeyedContainer")
    }
    
    func superDecoder() throws -> Decoder {
        throw PapyrusError("This shouldn't be called? http superDecoder")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        throw PapyrusError("This shouldn't be called? http superDecoder(forKey:)")
    }
}

private enum HTTPParameter {
    case body, header, query, path
}

private struct HTTPRequestSingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    
    let request: DecodableRequest
    let parameter: HTTPParameter
    let key: String
    
    func decodeNil() -> Bool {
        fatalError("`optional` not supported yet")
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `bool`")
        case .header:
            throw PapyrusError("`header` doesn't suport `bool`")
        case .path:
            throw PapyrusError("`path` doesn't suport `bool`")
        case .query:
            throw PapyrusError("`query` doesn't suport `bool`")
        }
    }
    
    func decode(_ type: String.Type) throws -> String {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `string`")
        case .header:
            return try self.request.getHeader(for: self.key)
        case .path:
            return try self.request.getPathComponent(for: self.key)
        case .query:
            return try self.request.getQuery(for: self.key)
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `double`")
        case .header:
            throw PapyrusError("`header` doesn't suport `double`")
        case .path:
            throw PapyrusError("`path` doesn't suport `double`")
        case .query:
            throw PapyrusError("`query` doesn't suport `double`")
        }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `float`")
        case .header:
            throw PapyrusError("`header` doesn't suport `float`")
        case .path:
            throw PapyrusError("`path` doesn't suport `float`")
        case .query:
            throw PapyrusError("`query` doesn't suport `float`")
        }
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `int`")
        case .header:
            throw PapyrusError("`header` doesn't suport `int`")
        case .path:
            throw PapyrusError("`path` doesn't suport `int`")
        case .query:
            throw PapyrusError("`query` doesn't suport `int`")
        }
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `int8`")
        case .header:
            throw PapyrusError("`header` doesn't suport `int8`")
        case .path:
            throw PapyrusError("`path` doesn't suport `int8`")
        case .query:
            throw PapyrusError("`query` doesn't suport `int8`")
        }
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `int16`")
        case .header:
            throw PapyrusError("`header` doesn't suport `int16`")
        case .path:
            throw PapyrusError("`path` doesn't suport `int16`")
        case .query:
            throw PapyrusError("`query` doesn't suport `int16`")
        }
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `int32`")
        case .header:
            throw PapyrusError("`header` doesn't suport `int32`")
        case .path:
            throw PapyrusError("`path` doesn't suport `int32`")
        case .query:
            throw PapyrusError("`query` doesn't suport `int32`")
        }
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `int64`")
        case .header:
            throw PapyrusError("`header` doesn't suport `int64`")
        case .path:
            throw PapyrusError("`path` doesn't suport `int64`")
        case .query:
            throw PapyrusError("`query` doesn't suport `int64`")
        }
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `uint`")
        case .header:
            throw PapyrusError("`header` doesn't suport `uint`")
        case .path:
            throw PapyrusError("`path` doesn't suport `uint`")
        case .query:
            throw PapyrusError("`query` doesn't suport `uint`")
        }
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `uint8`")
        case .header:
            throw PapyrusError("`header` doesn't suport `uint8`")
        case .path:
            throw PapyrusError("`path` doesn't suport `uint8`")
        case .query:
            throw PapyrusError("`query` doesn't suport `uint8`")
        }
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `uint16`")
        case .header:
            throw PapyrusError("`header` doesn't suport `uint16`")
        case .path:
            throw PapyrusError("`path` doesn't suport `uint16`")
        case .query:
            throw PapyrusError("`query` doesn't suport `uint16`")
        }
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `uint32`")
        case .header:
            throw PapyrusError("`header` doesn't suport `uint32`")
        case .path:
            throw PapyrusError("`path` doesn't suport `uint32`")
        case .query:
            throw PapyrusError("`query` doesn't suport `uint32`")
        }
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        switch self.parameter {
        case .body:
            throw PapyrusError("`body` doesn't suport `uint64`")
        case .header:
            throw PapyrusError("`header` doesn't suport `uint64`")
        case .path:
            throw PapyrusError("`path` doesn't suport `uint64`")
        case .query:
            throw PapyrusError("`query` doesn't suport `uint64`")
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        switch self.parameter {
        case .body:
            return try request.getBody()
        case .header:
            throw PapyrusError("`header` doesn't suport `T`")
        case .path:
            throw PapyrusError("`path` doesn't suport `T`")
        case .query:
            if type is String.Type {
                return try request.getQuery(for: self.key) as! T
            } else if type is Optional<String>.Type {
                return try request.getQuery(for: self.key) as! T
            } else {
                throw PapyrusError("`query` doesn't suport Encodable `T` of type \(T.self)")
            }
        }
    }
}

