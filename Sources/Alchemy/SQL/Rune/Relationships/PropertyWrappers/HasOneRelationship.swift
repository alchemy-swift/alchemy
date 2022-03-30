import NIO

/// Either side of a 1 - 1 relationship. The details of this
/// relationship are defined in the initializers inherited from
/// `HasRelationship`.
@propertyWrapper
public final class HasOneRelationship<From: Model, To: RelationshipAllowed>: Relationship {
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
        set { value = newValue }
    }
    
    // MARK: Overrides
    
    public init() {}
    
    // MARK: Relationship
    
    public static func defaultConfig() -> RelationshipMapping<From, To.Value> {
        return .defaultHas()
    }
    
    public func set(values: [To]) throws {
        wrappedValue = try To.from(values.first)
    }
}

extension HasOneRelationship: ModelProperty {
    public convenience init(key: String, on row: SQLRowReader) throws {
        self.init()
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {}
}

extension HasOneRelationship: Codable where To: Codable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        if let underlyingValue = value {
            try underlyingValue.encode(to: encoder)
        }
    }
}

extension HasOneRelationship: Equatable where To: Equatable {
    public static func == (lhs: HasOneRelationship<From, To>, rhs: HasOneRelationship<From, To>) -> Bool {
        lhs.value == rhs.value
    }
}
