import NIO

/// Either side of a M - M relationship or the parent of a 1 - M
/// relationship. The details of this relationship are defined
/// in the initializers inherited from `HasRelationship`.
@propertyWrapper
public final class HasManyRelationship<From: Model, To: RelationshipAllowed>: RelationshipOld {
    /// Internal value for storing the `To` objects of this
    /// relationship, when they are loaded.
    fileprivate var value: [To]?
    
    /// The related `[Model]` object. Accessing this will `fatalError`
    /// if the relationship is not already loaded via eager loading
    /// or set manually.
    public var wrappedValue: [To] {
        get {
            guard let value = value else {
                fatalError("HasManyRelationship of type `\(name(of: To.self))` on `\(name(of: From.self))` was not loaded!")
            }
            
            return value
        }
        set { value = newValue }
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
        wrappedValue = try values.map { try To.from($0) }
    }
}

extension HasManyRelationship: ModelProperty {
    public convenience init(key: String, on row: SQLRowReader) throws {
        self.init()
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {}
}

extension HasManyRelationship: Codable where To: Codable {
    public convenience init(from decoder: Decoder) throws { self.init() }
    
    public func encode(to encoder: Encoder) throws {
        if let underlyingValue = value {
            try underlyingValue.encode(to: encoder)
        }
    }
}

extension HasManyRelationship: Equatable where To: Equatable {
    public static func == (lhs: HasManyRelationship<From, To>, rhs: HasManyRelationship<From, To>) -> Bool {
        lhs.value == rhs.value
    }
}
