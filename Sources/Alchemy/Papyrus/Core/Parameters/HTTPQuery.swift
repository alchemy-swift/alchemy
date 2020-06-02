protocol AnyQuery {
    var value: Decodable { get }
}

@propertyWrapper
public struct HTTPQuery<Value: Decodable>: Decodable, AnyQuery {
    public var wrappedValue: Value
    var value: Decodable { wrappedValue }
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    public init(from decoder: Decoder) throws {
        guard let requestDecoder = decoder as? HTTPRequestDecoder else {
            fatalError("Can't decode without a request.")
        }
        
        self.wrappedValue = try requestDecoder.singleValueContainer().decode(Value.self)
    }
}
