extension Request {
    /// The HTTPMethod of the request.
    public var method: HTTPMethod {
        head.method
    }
    
    /// Any headers associated with the request.
    public var headers: HTTPHeaders {
        head.headers
    }
    
    /// The url components of this request.
    public var components: URLComponents? {
        URLComponents(string: head.uri)
    }
    
    /// The path of the request. Does not include the query string.
    public var path: String {
        URLComponents(string: head.uri)?.path ?? ""
    }
    
    /// Any query items parsed from the URL. These are not percent
    /// encoded.
    public var queryItems: [URLQueryItem] {
        URLComponents(string: head.uri)?.queryItems ?? []
    }
    
    /// Returns the first parameter for the given key, if there is one.
    ///
    /// Use this to fetch any parameters from the path.
    /// ```swift
    /// app.post("/users/:user_id") { request in
    ///     let userID = try request.parameter("user_id")?.int()
    ///     ...
    /// }
    /// ```
    public func parameter(_ key: String) -> Parameter? {
        parameters.first(where: { $0.key == key })
    }
    
    /// The body is a wrapper used to provide simple access to any
    /// body data, such as JSON.
    public var body: HTTPBody? {
        guard let bodyBuffer = bodyBuffer else {
            return nil
        }
        
        return HTTPBody(buffer: bodyBuffer)
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
            return try body.decodeJSON(as: type, with: decoder)
        } catch let DecodingError.keyNotFound(key, _) {
            throw ValidationError("Missing field `\(key.stringValue)` from request body.")
        } catch let DecodingError.typeMismatch(type, context) {
            let key = context.codingPath.last?.stringValue ?? "unknown"
            throw ValidationError("Request body field `\(key)` should be a `\(type)`.")
        } catch {
            throw ValidationError("Invalid request body.")
        }
    }
}
