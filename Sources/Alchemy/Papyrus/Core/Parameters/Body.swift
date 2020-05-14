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

protocol AnyBody {
    var content: AnyEncodable { get }
    var contentType: ContentType { get }
}

struct ErasedBody: AnyBody {
    var content: AnyEncodable
    var contentType: ContentType
}

public enum ContentType {
    case json, urlEncoded
}

@propertyWrapper
public struct Body<Value: Codable>: AnyBody {
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
}

extension Encodable {
    func toAny() -> AnyEncodable {
        .init(self)
    }
}
