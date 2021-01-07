import NIO

@propertyWrapper
/// Either side of a M - M relationship or the parent of a 1 - M relationship. The details of this
/// relationship are defined in the initializers inherited from `HasRelationship`.
public final class HasManyRelationship<
    From: Model,
    To: ModelMaybeOptional
>: HasRelationship<From, To>, Encodable, Relationship {
    /// Internal value for storing the `To` objects of this relationship, when they are loaded.
    private var value: [To]?
    
    /// The related `[Model]` object. Accessing this will `fatalError` if the relationship is not
    /// already loaded via eager loading or set manually.
    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Relationship of type `\(name(of: To.self))` was not loaded!")
            }
            return value
        }
        set { self.value = newValue }
    }
    
    /// The projected value of this property wrapper is itself. Used for when a reference to the
    /// _relationship_ type is needed, such as during eager loads.
    public var projectedValue: From.HasMany<To> { self }

    // MARK: Overrides
    
    public required init(
        propertyName: String? = nil,
        to key: KeyPath<To.Value, To.Value.BelongsTo<From>>,
        keyString: String = To.Value.keyMappingStrategy.map(input: "\(From.self)Id")
    ) {
        super.init(propertyName: propertyName, to: key, keyString: keyString)
    }
    
    public required init<Through: Model>(
        propertyName: String? = nil,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String = Through.keyMappingStrategy.map(input: "\(From.self)Id"),
        toString: String = Through.keyMappingStrategy.map(input: "\(To.Value.self)Id")
    ) {
        super.init(
            propertyName: propertyName,
            from: fromKey,
            to: toKey,
            fromString: fromString,
            toString: toString
        )
    }
    
    // MARK: Relationship
    
    public func loadRelationships(
        for from: [From],
        query nestedQuery: @escaping (ModelQuery<To.Value>) -> ModelQuery<To.Value>,
        into eagerLoadKeyPath: KeyPath<From, From.HasMany<To>>) -> EventLoopFuture<[From]>
    {
        self.eagerLoadClosure(nestedQuery)(from)
            .flatMapThrowing { dict in
                var updatedResults = [From]()
                for result in from {
                    let values = dict[result.id as! From.Value.Identifier]
                    let wrappedValue = try values?.map { try To.from($0) } ?? []
                    result[keyPath: eagerLoadKeyPath].wrappedValue = wrappedValue
                    updatedResults.append(result)
                }

                return updatedResults
        }
    }
    
    // MARK: Codable
    
    public func encode(to encoder: Encoder) throws {
        if !(encoder is ModelEncoder) {
            try self.value.encode(to: encoder)
        }
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
