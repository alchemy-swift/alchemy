/// A type from which a `RequestAllowed` can be decoded. Conform your
/// server's Request type to this for easy validation against a
/// `RequestAllowed` type.
public protocol DecodableRequest {
    /// Get a header for a given key.
    ///
    /// - Parameter key: The key of the header.
    /// - Returns: The value of the header for the given key, if it
    ///   exists.
    func header(for key: String) -> String?
    
    /// Get a url query value for a given key.
    ///
    /// - Parameter key: The key of the query.
    /// - Returns: The value of the query for the given key, if it
    ///   exists.
    func query(for key: String) -> String?
    
    /// Get a path component for a given key.
    ///
    /// - Parameter key: The key of the path component.
    /// - Returns: The value of the path component for the given key,
    ///   if it exists.
    func pathComponent(for key: String) -> String?
    
    /// Decode the body of a request as JSON.
    ///
    /// - Warning: Only JSON decoding is supported; there isn't
    ///   currently a way to detect if the `@Body` has a `contentType`
    ///   of `.urlEncoded` during decoding.
    ///
    /// - Throws: Any error thrown decoding the request body to `T`.
    /// - Returns: An instance of `T`, decoded from this request's
    ///   body.
    func decodeBody<T: Decodable>(encoding: BodyEncoding) throws -> T
}
