import NIO

@propertyWrapper
public final class HasOneRelationship<From: Model, To: RelationAllowed>: HasRelationship<From, To>, Encodable, Relationship
{
    private var value: To?
    
    public var projectedValue: HasOneRelationship<From, To> { self }

    public var wrappedValue: To {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }
    
    public init(value: To) {
        super.init()
        self.value = value
    }
    
    public required init(this: String, to key: KeyPath<To.Value, To.Value.BelongsTo<From>>, keyString: String) {
        super.init(this: this, to: key, keyString: keyString)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public required init<Through: Model>(
        named: String,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String
    ) {
        super.init(named: named, from: fromKey, to: toKey, fromString: fromString, toString: toString)
    }
    
    public func load(
        _ from: [From],
        from eagerLoadKeyPath: KeyPath<From, From.HasOne<To>>) -> EventLoopFuture<[From]>
    {
        self.eagerLoadClosure(from)
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = self.value as? To.Value {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}
