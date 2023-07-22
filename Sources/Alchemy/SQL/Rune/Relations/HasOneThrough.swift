extension Model {
    public typealias HasOneThrough<To: ModelOrOptional> = HasOneThroughRelation<Self, To>
}

extension HasOneRelation {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasOneThrough<To> {
        HasOneThroughRelation(db: db, from: from, fromKey: fromKey, toKey: toKey)
            .through(table, from: throughFromKey, to: throughToKey)
    }
}

public final class HasOneThroughRelation<From: Model, To: ModelOrOptional>: ThroughRelation<From, To> {}

