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
        self.wrappedValue = try decoder.singleValueContainer().decode(String.self)
    }
}
