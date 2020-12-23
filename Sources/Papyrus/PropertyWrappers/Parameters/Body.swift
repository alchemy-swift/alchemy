import Foundation

public struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    public init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }
    
    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

public protocol AnyBody {
    var content: AnyEncodable { get }
    var contentType: ContentType { get }
}

public enum ContentType {
    case json, urlEncoded
}

@propertyWrapper
public struct Body<Value: Codable>: Codable, AnyBody {
    public var contentType: ContentType = .json
    public var content: AnyEncodable { .init(wrappedValue) }
    
    public var wrappedValue: Value {
        get { _wrappedValue! }
        set { _wrappedValue = newValue }
    }
    
    private var _wrappedValue: Value?
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(_ contentType: ContentType) {
        self.contentType = contentType
    }
    
    public init(wrappedValue: Value, _ contentType: ContentType) {
        self.contentType = contentType
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        // do nothing
    }
}
