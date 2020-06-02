protocol AnyPath {
    var value: String { get }
}

@propertyWrapper
public struct Path: Decodable, AnyPath {
    public var wrappedValue: String
    var value: String { wrappedValue }

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        guard let requestDecoder = decoder as? HTTPRequestDecoder else {
            fatalError("Can't decode without a request.")
        }
        
        self.wrappedValue = try requestDecoder.singleValueContainer().decode(String.self)
    }
}
