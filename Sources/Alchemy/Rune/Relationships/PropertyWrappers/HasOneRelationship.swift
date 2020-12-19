import NIO

@propertyWrapper
/// Either side of a 1 - 1 relationship. The details of this relationship are defined in the
/// initializers inherited from `HasRelationship`.
public final class HasOneRelationship<
    From: Model,
    To: ModelMaybeOptional
>: HasRelationship<From, To>, Encodable, Relationship {
    /// Internal value for storing the `To` object of this relationship, when it is loaded.
    private var value: To?
    
    /// The projected value of this property wrapper is itself. Used for when a reference to the
    /// _relationship_ type is needed, such as during eager loads.
    public var projectedValue: HasOneRelationship<From, To> { self }

    /// The related `To` object. Accessing this will `fatalError` if the relationship is not already
    /// loaded via eager loading or set manually.
    public var wrappedValue: To {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }
    
    // MARK: Relationship
    
    public func loadRelationships(
        for from: [From],
        query nestedQuery: @escaping (ModelQuery<To.Value>) -> ModelQuery<To.Value>,
        into eagerLoadKeyPath: KeyPath<From, From.HasOne<To>>) -> EventLoopFuture<[From]>
    {
        self.eagerLoadClosure(nestedQuery)(from)
            .flatMapThrowing { dict in
                var updatedResults = [From]()
                for result in from {
                    let values = dict[result.id as! From.Value.Identifier]
                    result[keyPath: eagerLoadKeyPath].wrappedValue = try To.from(values?.first)
                    updatedResults.append(result)
                }

                return updatedResults
        }
    }
    
    // MARK: Codable
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {}
}
