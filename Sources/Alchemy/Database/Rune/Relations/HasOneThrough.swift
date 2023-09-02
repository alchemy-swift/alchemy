extension Model {
    public typealias HasOneThrough<To: ModelOrOptional> = HasOneThroughRelation<Self, To>
}

extension HasOneRelation {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasOneThrough<To> {
        HasOneThroughRelation(hasOne: self, through: table, fromKey: throughFromKey, toKey: throughToKey)
    }
}

public final class HasOneThroughRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    init(hasOne: HasOneRelation<From, To>, through table: String, fromKey: String?, toKey: String?) {
        super.init(db: hasOne.db, from: hasOne.from, fromKey: hasOne.fromKey, toKey: hasOne.toKey)
        through(table, from: fromKey, to: toKey)
    }

    @discardableResult
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        var from: SQLKey = db.inferReferenceKey(From.self).specify(throughFromKey)
        if let through = throughs.last {
            from = from.infer(db.inferReferenceKey(through.table).string)
        }

        let to: SQLKey = db.inferPrimaryKey().specify(throughToKey)
        toKey = toKey.infer(db.inferReferenceKey(table).string)
        return _through(table: table, from: from, to: to)
    }

    @discardableResult
    public func through(_ model: (some Model).Type, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        var from: SQLKey = db.inferReferenceKey(From.self).specify(throughFromKey)
        if let through = throughs.last {
            from = from.infer(db.inferReferenceKey(through.table).string)
        }

        let to: SQLKey = .infer(model.primaryKey).specify(throughToKey)
        toKey = toKey.infer(db.inferReferenceKey(model).string)
        return _through(table: model.table, from: from, to: to)
    }
}
