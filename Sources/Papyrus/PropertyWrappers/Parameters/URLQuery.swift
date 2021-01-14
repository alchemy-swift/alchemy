/// An erased `HTTPQuery`.
protocol AnyQuery {
    /// The value of this query.
    var value: Codable { get }
}

/// Represents a value in the query of an endpoint's URL.
@propertyWrapper
public struct URLQuery<Value: Codable>: Codable, AnyQuery {
    // MARK: AnyQuery
    
    public var value: Codable { wrappedValue }
    
    /// The value of the query item.
    public var wrappedValue: Value
    
    /// Initialize with a query value.
    ///
    /// - Parameter wrappedValue: The value of this query item.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    // MARK: Decodable
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }
}
