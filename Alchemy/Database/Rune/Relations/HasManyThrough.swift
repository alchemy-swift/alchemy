extension Model {
    public typealias HasManyThrough<To: Many> = HasManyThroughRelationship<Self, To>

    public func hasManyThrough<To: Many>(db: Database = To.M.database,
                                          _ through: String,
                                          fromKey: String? = nil,
                                          toKey: String? = nil,
                                          throughFromKey: String? = nil,
                                          throughToKey: String? = nil) -> HasManyThrough<To> {
        hasMany(To.self, on: db, from: fromKey, to: toKey)
            .through(through, from: throughFromKey, to: throughToKey)
    }
}

extension HasManyRelationship {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasManyThrough<M> {
        HasManyThroughRelationship(hasMany: self, through: table, fromKey: throughFromKey, toKey: throughToKey)
    }
}

public final class HasManyThroughRelationship<From: Model, M: Many>: Relationship<From, M> {
    public init(hasMany: HasManyRelationship<From, M>, through table: String, fromKey: String?, toKey: String?) {
        super.init(db: hasMany.db, from: hasMany.from, fromKey: hasMany.fromKey, toKey: hasMany.toKey)
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

        let to: SQLKey = .infer(model.idKey).specify(throughToKey)
        toKey = toKey.infer(db.inferReferenceKey(model).string)
        return _through(table: model.table, from: from, to: to)
    }
}
