protocol AnyHeader {
    var keyOverride: String? { get }
    var value: String { get }
}

@propertyWrapper
public struct Header: Decodable, AnyHeader {
    public var wrappedValue: String
    var keyOverride: String?
    var value: String { wrappedValue }
    
    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
    
    public init(wrappedValue: String, key: String? = nil) {
        self.wrappedValue = wrappedValue
        self.keyOverride = key
    }
    
    public init(from decoder: Decoder) throws {
        guard let requestDecoder = decoder as? HTTPRequestDecoder else {
            fatalError("Can't decode without a request.")
        }
        
        self.wrappedValue = try requestDecoder.singleValueContainer().decode(String.self)
    }
}
