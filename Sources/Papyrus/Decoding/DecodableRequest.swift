/// A type from which a `RequestAllowed` can be decoded. Conform your server's Request type to this
/// for easy validation against a `RequestAllowed` type.
public protocol DecodableRequest {
    /// Get a header for a given key.
    ///
    /// - Parameter key: the key of the header.
    /// - Returns: the value of the header for the given key, if it exists.
    func getHeader(for key: String) -> String?
    
    /// Get a url query value for a given key.
    ///
    /// - Parameter key: the key of the query.
    /// - Returns: the value of the query for the given key, if it exists.
    func getQuery(for key: String) -> String?
    
    /// Get a path component for a given key.
    ///
    /// - Parameter key: the key of the path component.
    /// - Returns: the value of the path component for the given key, if it exists.
    func getPathComponent(for key: String) -> String?
    
    /// Decode the body of a request as JSON.
    ///
    /// - Warning: only JSON decoding is supported; there isn't currently a way to detect if the
    ///            `@Body` has a `contentType` of `.urlEncoded` during decoding.
    ///
    /// - Throws: any error thrown in decoding the request body to `T`.
    /// - Returns: an instance of `T`, decoded from this requests body.
    func getBody<T: Decodable>() throws -> T
}
