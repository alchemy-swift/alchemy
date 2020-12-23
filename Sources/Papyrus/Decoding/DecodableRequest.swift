/// A type from which a `RequestAllowed` can be decoded. Conform your server's Request type to this
/// for easy validation against a `RequestAllowed` type.
public protocol DecodableRequest {
    /// Get a header for a given key. Throw if it does not exist.
    ///
    /// - Parameter key: the key of the header.
    /// - Throws: if the request headers have no value for the given `key`.
    /// - Returns: the value of the header for the given key.
    func getHeader(for key: String) throws -> String
    
    /// Get a url query value for a given key. Throw if it does not exist.
    ///
    /// - Parameter key: the key of the query.
    /// - Throws: if the query has no value for the key.
    /// - Returns: the value of the query for the given key.
    func getQuery(for key: String) throws -> String
    
    /// Get a path component for a given key. Throw if it does not exist.
    ///
    /// - Parameter key: the key of the path component.
    /// - Throws: if the path component has no value for the key.
    /// - Returns: the value of the path component for the given key.
    func getPathComponent(for key: String) throws -> String
    
    /// Decode the body of a request as a certain type.
    ///
    /// - Throws: any error thrown in decoding the request body to `T`.
    /// - Returns: an instance of `T`, decoded from this requests body.
    func getBody<T: Decodable>() throws -> T
}
