protocol AnyQuery {
    var value: Decodable { get }
}

@propertyWrapper
public struct HTTPQuery<Value: Decodable>: Decodable, AnyQuery {
    public var wrappedValue: Value
    var value: Decodable { wrappedValue }
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }
}
