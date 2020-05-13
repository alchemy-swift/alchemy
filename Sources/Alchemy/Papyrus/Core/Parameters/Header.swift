protocol AnyHeader {
    var keyOverride: String? { get }
    var value: String { get }
}

@propertyWrapper
public struct Header: AnyHeader {
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
}
