/// Represents the HTTP method, or verb, of a request. There are
/// static accessors for `GET`, `POST`, `PUT`, `PATCH`, and
/// `DELETE`, but any custom one can be made with the
/// public initializer.
public struct EndpointMethod: Equatable {
    /// `DELETE` method.
    public static let delete = EndpointMethod("DELETE")
    
    /// `GET` method.
    public static let get = EndpointMethod("GET")
    
    /// `PATCH` method.
    public static let patch = EndpointMethod("PATCH")
    
    /// `POST` method.
    public static let post = EndpointMethod("POST")
    
    /// `PUT` method.
    public static let put = EndpointMethod("PUT")
    
    /// The raw string value of this method.
    public let rawValue: String
    
    /// Creates an `EndpointMethod` with the specified `String`.
    ///
    /// - Parameter rawValue: The `String` of the method name.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
