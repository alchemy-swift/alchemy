extension Model {
    public typealias HasManyThrough<To: Model> = HasManyThroughRelation<Self, To>
}

extension HasManyRelation {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasManyThrough<M> {
        HasManyThroughRelation(db: db, from: from, fromKey: fromKey, toKey: toKey)
            .through(table, from: throughFromKey, to: throughToKey)
    }
}

public final class HasManyThroughRelation<From: Model, M: Model>: ThroughRelation<From, [M]> {}
