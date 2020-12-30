/// An erased `HTTPQuery`.
protocol AnyQuery {
    /// An override for the query key. By default, the key is the name of the property.
    var keyOverride: String? { get }
    
    /// The value of this query.
    var value: Codable { get }
}

@propertyWrapper
/// Represents a value in the query of an endpoint's URL.
public struct URLQuery<Value: Codable>: Codable, AnyQuery {
    /// The value of the query item.
    public var wrappedValue: Value

    // MARK: AnyQuery
    
    public var keyOverride: String?
    public var value: Codable { wrappedValue }
    
    /// Initialize with a query value.
    ///
    /// - Parameter wrappedValue: the value of this query item.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    /// Intialize with a query value and custom key.
    ///
    /// - Parameters:
    ///   - wrappedValue: the value of this query item.
    ///   - key: the key of this query item. Defaults to nil which means the name of whatever
    ///          property this wraps name will be treated as the key.
    public init(wrappedValue: Value, key: String? = nil) {
        self.wrappedValue = wrappedValue
        self.keyOverride = key
    }
    
    // MARK: Decodable
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }
}
