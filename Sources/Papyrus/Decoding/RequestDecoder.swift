/// The strategy for mapping the property names in the `DecodableRequest` type to their correlating
/// fields (header, query, path parameter, etc) on a request.
typealias KeyMapping = (String) -> String

/// A component of an HTTP request.
private enum RequestComponent {
    /// The request body.
    case body
    /// The request headers.
    case header
    /// The request query string.
    case query
    /// The request path.
    case path
}

/// Decodes a `EndpointRequest` from a `DecodableRequest`. Technically, this can decode any
/// `Decodable` type, but it will error out on any field that isn't `@Body`, `@Header`, `@Path` or
/// `@Query`.
struct RequestDecoder: Decoder {
    /// The `DecodableRequest` from which fields on the `EndpointRequest` will be decoded.
    let request: DecodableRequest
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyedContainer(request: self.request))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { try error() }
    func singleValueContainer() throws -> SingleValueDecodingContainer { try error() }
}

/// Decodes a value from a single component of the request.
private struct RequestComponentDecoder: Decoder {
    /// The request to decode from.
    let request: DecodableRequest
    
    /// The parameter of the request to decode from.
    let param: RequestComponent
    
    /// The key to decode with.
    let key: String

    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws
        -> KeyedDecodingContainer<Key> where Key : CodingKey { try error() }
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { try error() }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        RequestComponentContainer(request: self.request, parameter: self.param, key: self.key)
    }
}

/// A keyed container for routing which request component a value should decode from.
private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    /// The request from which we are decoding.
    let request: DecodableRequest
    
    // MARK: KeyedDecodingContainerProtocol
    
    var codingPath: [CodingKey] = []
    var allKeys: [Key] = []
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        if type is Header.Type {
            return try T(
                from: RequestComponentDecoder(
                    request: self.request,
                    param: .header,
                    key: key.stringValue
                )
            )
        } else if type is AnyBody.Type {
            return try T(
                from: RequestComponentDecoder(
                    request: self.request,
                    param: .body,
                    key: key.stringValue
                )
            )
        } else if type is AnyQuery.Type {
            return try T(
                from: RequestComponentDecoder(
                    request: self.request,
                    param: .query,
                    key: key.stringValue
                )
            )
        } else if type is Path.Type {
            return try T(
                from: RequestComponentDecoder(
                    request: self.request,
                    param: .path,
                    key: key.stringValue
                )
            )
        } else {
            return try error()
        }
    }
    
    func contains(_ key: Key) -> Bool { true }
    func decodeNil(forKey key: Key) throws -> Bool { try error() }
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try error() }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try error() }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try error() }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try error() }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try error() }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try error() }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try error() }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try error() }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try error() }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try error() }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try error() }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try error() }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try error() }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try error() }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
        -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { try error() }
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { try error() }
    func superDecoder() throws -> Decoder { try error() }
    func superDecoder(forKey key: Key) throws -> Decoder { try error() }
}

/// A single value container for decoding a value from a specific request component.
private struct RequestComponentContainer: SingleValueDecodingContainer {
    let request: DecodableRequest
    let parameter: RequestComponent
    let key: String
    
    // MARK: SingleValueDecodingContainer
    
    var codingPath: [CodingKey] = []
    
    func decodeNil() -> Bool { false }
    func decode(_ type: Bool.Type) throws -> Bool { try unsupported(type) }
    
    func decode(_ type: String.Type) throws -> String {
        switch self.parameter {
        case .body:
            return try unsupported(type)
        case .header:
            return try self.request.getHeader(for: self.key).unwrap(or: self.nilError())
        case .path:
            return try self.request.getPathComponent(for: self.key).unwrap(or: self.nilError())
        case .query:
            return try self.request.getQuery(for: self.key).unwrap(or: self.nilError())
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double { try unsupported(type) }
    func decode(_ type: Float.Type) throws -> Float { try unsupported(type) }
    func decode(_ type: Int.Type) throws -> Int { try unsupported(type) }
    func decode(_ type: Int8.Type) throws -> Int8 { try unsupported(type) }
    func decode(_ type: Int16.Type) throws -> Int16 { try unsupported(type) }
    func decode(_ type: Int32.Type) throws -> Int32 { try unsupported(type) }
    func decode(_ type: Int64.Type) throws -> Int64 { try unsupported(type) }
    func decode(_ type: UInt.Type) throws -> UInt { try unsupported(type) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try unsupported(type) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try unsupported(type) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try unsupported(type) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try unsupported(type) }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        switch self.parameter {
        case .body:
            return try self.request.getBody(encoding: .json)
        case .header:
            return try self.unsupported(type)
        case .path:
            return try self.unsupported(type)
        case .query:
            if type is String.Type {
                return try self.request.getQuery(for: self.key).unwrap(or: self.nilError()) as! T
            } else if type is Optional<String>.Type {
                return self.request.getQuery(for: self.key) as! T
            } else if type is Int.Type {
                let query = try self.request.getQuery(for: self.key).unwrap(or: self.nilError())
                let errorMessage = "`\(self.key)` was `\(query)`. It must be an `Int`."
                let int = try Int(query).unwrap(or: PapyrusValidationError(errorMessage))
                return int as! T
            } else if type is Optional<Int>.Type {
                let int = try self.request.getQuery(for: self.key)
                    .map { string -> Int in
                        let errorMessage = "`\(self.key)` was `\(string)`. It must be an `Int`."
                        return try Int(string).unwrap(or: PapyrusValidationError(errorMessage))
                    }
                return int as! T
            } else {
                return try self.unsupported(type)
            }
        }
    }
    
    /// Throws an error letting the user know this component / type combo isn't supported _yet_.
    ///
    /// - Throws: guaranteed to throw a `PapyrusError`.
    /// - Returns: a generic type, though this never returns.
    private func unsupported<T>(_ type: T.Type) throws -> T {
        throw PapyrusError("decoding a `\(type)` from the \(self.parameter) isn't supported yet.")
    }
    
    /// Generates a `PapyrusError` with a message describing a nil value for a key that was
    /// expected.
    ///
    /// - Returns: the error to throw when a value is missing.
    private func nilError() -> PapyrusValidationError {
        PapyrusValidationError("Need a value for key `\(self.key)` in the `\(self.parameter)`.")
    }
}

/// Throws an error letting the user know of the acceptable properties on an `EndpointRequest`.
///
/// - Throws: guaranteed to throw a `PapyrusError`.
/// - Returns: a generic type, though this never returns.
private func error<T>() throws -> T {
    throw PapyrusError("Only properties wrapped by @Body, @Path, @Header, or @Query are " +
                        "supported on an `EndpointRequest`")
}
