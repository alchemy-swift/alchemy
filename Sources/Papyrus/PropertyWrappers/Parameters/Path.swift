@propertyWrapper
/// Represents a path component value on an endpoint. This value will replace a path component with
/// the name of the property this wraps.
public struct Path: Codable {
    /// The value of this path component.
    public var wrappedValue: String
    
    /// Initialize with a path component value.
    ///
    /// - Parameter wrappedValue: the value of this path component.
    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }

    // MARK: Decodable
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(String.self)
    }
}
