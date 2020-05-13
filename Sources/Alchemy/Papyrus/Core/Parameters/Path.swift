protocol AnyPath {
//    var customKey: String? { get }
    var value: String { get }
}

@propertyWrapper
public struct Path: AnyPath {
    public var wrappedValue: String
//    var customKey: String?
    var value: String { wrappedValue }

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }

//    public init(wrappedValue: String = "", key: String? = nil) {
//        self.wrappedValue = wrappedValue
//        self.customKey = key
//    }
}
