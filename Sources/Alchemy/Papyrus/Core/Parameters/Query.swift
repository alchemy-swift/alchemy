protocol AnyQuery {
    var value: Decodable { get }
}

@propertyWrapper
public struct Query<T: Decodable>: AnyQuery {
    public var wrappedValue: T
    var value: Decodable { wrappedValue }
    public init(wrappedValue: T) { self.wrappedValue = wrappedValue }
}
