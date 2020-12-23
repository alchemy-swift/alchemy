@propertyWrapper
/// Represents an item in a request's headers.
public struct Header: Codable {
    /// An override for the query key. By default, the key is the name of the property this wraps.
    public var keyOverride: String?
    
    /// The value of the this header.
    public var wrappedValue: String
    
    /// Initialize with a header value.
    ///
    /// - Parameter wrappedValue: the value of this header.
    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
    
    /// Intialize with a value and custom key.
    ///
    /// - Parameters:
    ///   - wrappedValue: the value of this header.
    ///   - key: the key of this header. Defaults to nil which means the name of whatever property
    ///          this wraps name will be treated as the key.
    public init(wrappedValue: String, key: String? = nil) {
        self.wrappedValue = wrappedValue
        self.keyOverride = key
    }
    
    // MARK: Decodable
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(String.self)
    }
}
