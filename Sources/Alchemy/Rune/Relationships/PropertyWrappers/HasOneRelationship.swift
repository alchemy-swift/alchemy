import NIO

/// Either side of a 1 - 1 relationship. The details of this
/// relationship are defined in the initializers inherited from
/// `HasRelationship`.
@propertyWrapper
public final class HasOneRelationship<
    From: Model,
    To: ModelMaybeOptional
>: AnyHas, Codable, Relationship {
    /// Internal value for storing the `To` object of this
    /// relationship, when it is loaded.
    fileprivate var value: To?
    
    /// The projected value of this property wrapper is itself. Used
    /// for when a reference to the _relationship_ type is needed,
    /// such as during eager loads.
    public var projectedValue: HasOneRelationship<From, To> { self }

    /// The related `To` object. Accessing this will `fatalError` if
    /// the relationship is not already loaded via eager loading or
    /// set manually.
    public var wrappedValue: To {
        get {
            do {
                return try To.from(value)
            } catch {
                fatalError("Relationship of type `\(name(of: To.self))` was not loaded!")
            }
        }
        set { self.value = newValue }
    }
    
    // MARK: Overrides
    
    public init() {}
    
    // MARK: Relationship
    
    public static func defaultConfig() -> RelationshipMapping<From, To.Value> {
        return .defaultHas()
    }
    
    public func set(values: [To]) throws {
        self.wrappedValue = try To.from(values.first)
    }
    
    // MARK: Codable
    
    public init(from decoder: Decoder) throws {}
    
    public func encode(to encoder: Encoder) throws {
        if !(encoder is ModelEncoder) {
            try self.value.encode(to: encoder)
        }
    }
}

public extension KeyedEncodingContainer {
    // Only encode the underlying value if it exists.
    mutating func encode<From, To>(_ value: HasOneRelationship<From, To>, forKey key: Key) throws {
        if let underlyingValue = value.value {
            try encode(underlyingValue, forKey: key)
        }
    }
}
