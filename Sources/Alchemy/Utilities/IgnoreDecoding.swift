@propertyWrapper
struct IgnoreDecoding<T>: Decodable {
    var wrappedValue: T?
    
    init(from decoder: Decoder) throws {
        wrappedValue = nil
    }
    
    init() {
        wrappedValue = nil
    }
}
