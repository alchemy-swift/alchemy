public protocol AnyQuery {
    var value: Codable { get }
}

@propertyWrapper
public struct HTTPQuery<Value: Codable>: Codable, AnyQuery {
    public var wrappedValue: Value
    public var value: Codable { wrappedValue }
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }
}
