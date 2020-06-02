import Foundation

/// Tools for decoding
extension HTTPRequest {
    public func getHeader(for key: String) throws -> String {
        try self.headers.first(name: key)
            .unwrap(or: SwiftAPIError(message: "Expected `\(key)` in the request headers."))
    }
    
    public func getQuery<T: Decodable>(for key: String) throws -> T {
        do {
            throw SwiftAPIError(message: "not available yet")
        } catch {
            throw SwiftAPIError(message: "Encountered an error getting `\(key)` from the request query. \(error).")
        }
    }
    
    public func pathComponent(for key: String) throws -> String {
        try self.pathParameters.first(where: { $0.parameter == key })
            .unwrap(or: SwiftAPIError(message: "Expected `\(key)` in the request path components."))
            .stringValue
    }
    
    public func getBody<T>() throws -> T where T : Decodable {
        do {
            return try self.body
                .unwrap(or: HTTPError(.internalServerError))
                .decodeJSON(as: T.self)
        } catch {
            throw SwiftAPIError(message: "Encountered an error decoding the body to type `\(T.self)`: \(error)")
        }
    }
}

import Foundation

/// Decodes a `Decodable` from a `DatabaseRow`.
struct HTTPRequestDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let request: HTTPRequest
    let keyMappingStrategy: DatabaseKeyMappingStrategy
    
    init(request: HTTPRequest, keyMappingStrategy: DatabaseKeyMappingStrategy) {
        self.request = request
        self.keyMappingStrategy = keyMappingStrategy
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedContainer(request: self.request, keyMappingStrategy: self.keyMappingStrategy))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        /// This is for arrays, which we currently support in other ways.
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DatabaseDecodingError("This shouldn't be called; top level is keyed.")
    }
}

struct HTTPDecodingError: Error {
    let info: String
    init(_ info: String) { self.info = info }
}

private struct HTTPParamDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    let request: HTTPRequest
    let param: HTTPParameter
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        throw HTTPDecodingError("`container` shouldn't be called; this is only for single values.")
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw HTTPDecodingError("`unkeyedContainer` shouldn't be called; this is only for single values.")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        HTTPRequestSingleValueDecodingContainer(request: self.request, parameter: self.param)
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
    
    let request: HTTPRequest
    let keyMappingStrategy: DatabaseKeyMappingStrategy
    
    private func string(for key: Key) -> String {
        self.keyMappingStrategy.map(input: key.stringValue)
    }
    
    func contains(_ key: Key) -> Bool {
        fatalError("`contains` unsupported")
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        throw HTTPDecodingError("`decodeNil` unsupported.")
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        throw HTTPDecodingError("`bool` unsupported.")
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        throw HTTPDecodingError("`string` unsupported.")
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        throw HTTPDecodingError("`double` unsupported.")
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        throw HTTPDecodingError("`float` unsupported.")
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        throw HTTPDecodingError("`int` unsupported.")
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        throw HTTPDecodingError("`int8` unsupported.")
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        throw HTTPDecodingError("`int16` unsupported.")
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        throw HTTPDecodingError("`int32` unsupported.")
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        throw HTTPDecodingError("`int64` unsupported.")
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        throw HTTPDecodingError("`uint` unsupported.")
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        throw HTTPDecodingError("`uint8` unsupported.")
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        throw HTTPDecodingError("`uint16` unsupported.")
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        throw HTTPDecodingError("`uint32` unsupported.")
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        throw HTTPDecodingError("`uint64` unsupported.")
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        if type is AnyHeader.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .header))
        } else if type is AnyBody.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .body))
        } else if type is AnyQuery.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .query))
        } else if type is AnyPath.Type {
            return try T(from: HTTPParamDecoder(request: self.request, param: .path))
        } else {
            throw HTTPDecodingError("`\(name(of: type))` unsupported.")
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw HTTPDecodingError("This shouldn't be called? http nextedContainer")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw HTTPDecodingError("This shouldn't be called? http nestedUnkeyedContainer")
    }
    
    func superDecoder() throws -> Decoder {
        throw HTTPDecodingError("This shouldn't be called? http superDecoder")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        throw HTTPDecodingError("This shouldn't be called? http superDecoder(forKey:)")
    }
}

private enum HTTPParameter {
    case body, header, query, path
}

private struct HTTPRequestSingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    
    let request: HTTPRequest
    let parameter: HTTPParameter
    
    func decodeNil() -> Bool {
        fatalError("`optional` not supported yet")
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `bool`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `bool`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `bool`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `bool`")
        }
    }
    
    func decode(_ type: String.Type) throws -> String {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `string`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `string`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `string`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `string`")
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `double`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `double`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `double`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `double`")
        }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `float`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `float`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `float`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `float`")
        }
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `int`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `int`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `int`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `int`")
        }
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `int8`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `int8`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `int8`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `int8`")
        }
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `int16`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `int16`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `int16`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `int16`")
        }
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `int32`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `int32`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `int32`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `int32`")
        }
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `int64`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `int64`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `int64`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `int64`")
        }
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `uint`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `uint`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `uint`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `uint`")
        }
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `uint8`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `uint8`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `uint8`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `uint8`")
        }
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `uint16`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `uint16`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `uint16`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `uint16`")
        }
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `uint32`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `uint32`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `uint32`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `uint32`")
        }
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `uint64`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `uint64`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `uint64`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `uint64`")
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        switch self.parameter {
        case .body:
            throw HTTPDecodingError("`body` doesn't suport `T`")
        case .header:
            throw HTTPDecodingError("`header` doesn't suport `T`")
        case .path:
            throw HTTPDecodingError("`path` doesn't suport `T`")
        case .query:
            throw HTTPDecodingError("`query` doesn't suport `T`")
        }
    }
}
