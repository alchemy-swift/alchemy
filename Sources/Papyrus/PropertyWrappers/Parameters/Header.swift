/// Represents an item in a request's headers.
@propertyWrapper
public struct Header: Codable {
    /// The value of the this header.
    public var wrappedValue: String
    
    /// Initialize with a header value. The key for this header will
    /// be the name of the property this wraps.
    ///
    /// - Parameter wrappedValue: The value of this header.
    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
    
    // MARK: Decodable
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(String.self)
    }
}
