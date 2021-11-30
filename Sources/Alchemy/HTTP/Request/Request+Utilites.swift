extension Request {
    /// The HTTPMethod of the request.
    public var method: HTTPMethod { head.method }
    /// Any headers associated with the request.
    public var headers: HTTPHeaders { head.headers }
    /// The url components of this request.
    public var components: URLComponents? { URLComponents(string: head.uri) }
    /// The path of the request. Does not include the query string.
    public var path: String { components?.path ?? "" }
    /// Any query items parsed from the URL. These are not percent encoded.
    public var queryItems: [URLQueryItem] { components?.queryItems ?? [] }
    
    /// Returns the first parameter for the given key, if there is one.
    ///
    /// Use this to fetch any parameters from the path.
    /// ```swift
    /// app.post("/users/:user_id") { request in
    ///     let userId: Int = try request.parameter("user_id")
    ///     ...
    /// }
    /// ```
    public func parameter<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) throws -> L {
        guard let parameterString: String = parameter(key) else {
            throw ValidationError("expected parameter \(key)")
        }
        
        guard let converted = L(parameterString) else {
            throw ValidationError("parameter \(key) was \(parameterString) which couldn't be converted to \(name(of: L.self))")
        }
        
        return converted
    }
    
    /// The body is a wrapper used to provide simple access to any
    /// body data, such as JSON.
    public var body: Content? {
        guard let bodyBuffer = bodyBuffer else {
            return nil
        }
        
        return Content(buffer: bodyBuffer)
    }
    
    /// A dictionary with the contents of this Request's body.
    /// - Throws: Any errors from decoding the body.
    /// - Returns: A [String: Any] with the contents of this Request's
    ///   body.
    public func decodeBodyDict() throws -> [String: Any]? {
        try body?.decodeJSONDictionary()
    }
    
    /// Decodes the request body to the given type using the given
    /// `JSONDecoder`.
    ///
    /// - Returns: The type, decoded as JSON from the request body.
    public func decodeBodyJSON<T: Decodable>(as type: T.Type = T.self, with decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let body = try body.unwrap(or: ValidationError("Expecting a request body."))
        do {
            return try body.decode(as: type, with: decoder)
        } catch let DecodingError.keyNotFound(key, context) {
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            let pathWithKey = path.isEmpty ? key.stringValue : "\(path).\(key.stringValue)"
            throw ValidationError("Missing field `\(pathWithKey)` from request body.")
        } catch let DecodingError.typeMismatch(type, context) {
            let key = context.codingPath.last?.stringValue ?? "unknown"
            throw ValidationError("Request body field `\(key)` should be a `\(type)`.")
        } catch {
            throw ValidationError("Invalid request body.")
        }
    }
}
