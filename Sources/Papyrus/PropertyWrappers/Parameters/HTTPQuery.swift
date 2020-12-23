public protocol AnyQuery {
    var keyOverride: String? { get }
    var value: Codable { get }
}

@propertyWrapper
public struct HTTPQuery<Value: Codable>: Codable, AnyQuery {
    public var keyOverride: String?
    public var wrappedValue: Value
    public var value: Codable { wrappedValue }
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(wrappedValue: Value, key: String? = nil) {
        self.wrappedValue = wrappedValue
        self.keyOverride = key
    }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }
}
