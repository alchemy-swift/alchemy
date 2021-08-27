import NIO

/// Either side of a M - M relationship or the parent of a 1 - M
/// relationship. The details of this relationship are defined
/// in the initializers inherited from `HasRelationship`.
@propertyWrapper
public final class HasManyRelationship<
    From: Model,
    To: ModelMaybeOptional
>: AnyHas, Codable, Relationship {
    /// Internal value for storing the `To` objects of this
    /// relationship, when they are loaded.
    fileprivate var value: [To]?
    
    /// The related `[Model]` object. Accessing this will `fatalError`
    /// if the relationship is not already loaded via eager loading
    /// or set manually.
    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Relationship of type `\(name(of: To.self))` was not loaded!")
            }
            return value
        }
        set { self.value = newValue }
    }
    
    /// The projected value of this property wrapper is itself. Used
    /// for when a reference to the _relationship_ type is needed,
    /// such as during eager loads.
    public var projectedValue: From.HasMany<To> { self }

    // MARK: Overrides
    
    public init() {}
    
    // MARK: Relationship
    
    public static func defaultConfig() -> RelationshipMapping<From, To.Value> {
        return .defaultHas()
    }
    
    public func set(values: [To]) throws {
        self.wrappedValue = try values.map { try To.from($0) }
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
    mutating func encode<From, To>(_ value: HasManyRelationship<From, To>, forKey key: Key) throws {
        if let underlyingValue = value.value {
            try encode(underlyingValue, forKey: key)
        }
    }
}
