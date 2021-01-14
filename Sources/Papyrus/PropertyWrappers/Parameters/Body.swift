import Foundation

/// An erased `Encodable`.
public struct AnyEncodable: Encodable {
    /// Closure for encoding, erasing the type of the instance this
    /// class was instantiated with.
    private let _encode: (Encoder) throws -> Void
    
    /// Initialize with a generic `Encodable` instance.
    ///
    /// - Parameter wrapped: An instance of `Encodable`.
    public init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }
    
    // MARK: Encodable
    
    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

/// A type erased body of a request.
public protocol AnyBody {
    /// The `Encodable` content of this request.
    var content: AnyEncodable { get }
}

/// Represents the body of a request.
@propertyWrapper
public struct Body<Value: Codable>: Codable, AnyBody {
    /// The value of the this body.
    public var wrappedValue: Value {
        get { _wrappedValue! }
        set { _wrappedValue = newValue }
    }
    
    /// Local storage of the value of this body.
    private var _wrappedValue: Value?
    
    // MARK: AnyBody
    public var content: AnyEncodable { .init(self.wrappedValue) }
    
    /// Initialize with a content value.
    ///
    /// - Parameter wrappedValue: The content of this request.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    // MARK: Codable
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }
    
    public func encode(to encoder: Encoder) throws {}
}
