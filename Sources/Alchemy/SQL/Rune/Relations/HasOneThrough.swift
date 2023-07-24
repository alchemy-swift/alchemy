extension Model {
    public typealias HasOneThrough<To: ModelOrOptional> = HasOneThroughRelation<Self, To>
}

extension HasOneRelation {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasOneThrough<To> {
        HasOneThroughRelation(db: db, from: from, fromKey: fromKey, toKey: toKey)
            .through(table, from: throughFromKey, to: throughToKey)
    }
}

public final class HasOneThroughRelation<From: Model, To: ModelOrOptional>: ThroughRelation<From, To> {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: OR throughs.last.table.referenceKey if another through exists!
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(db.keyMapping.encode("Id")).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        return _through(table: table, from: from, to: to)
    }

    public func through(_ model: (some Model).Type, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: OR throughs.last.table.referenceKey if another through exists!
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(model.idKey).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        return _through(table: model.table, from: from, to: to)
    }
}
