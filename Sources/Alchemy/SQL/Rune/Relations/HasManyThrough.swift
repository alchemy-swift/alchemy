extension Model {
    public typealias HasManyThrough<To: Model> = HasManyThroughRelation<Self, To>
}

extension HasManyRelation {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasManyThrough<M> {
        HasManyThroughRelation(hasMany: self, through: table, fromKey: throughFromKey, toKey: throughToKey)
    }
}

public final class HasManyThroughRelation<From: Model, M: Model>: Relation<From, [M]> {

    init(hasMany: HasManyRelation<From, M>, through table: String, fromKey: String?, toKey: String?) {
        super.init(db: hasMany.db, from: hasMany.from, fromKey: hasMany.fromKey, toKey: hasMany.toKey)
        through(table, from: fromKey, to: toKey)
    }

    @discardableResult
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: OR throughs.last.table.referenceKey if another through exists!
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(db.keyMapping.encode("Id")).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        return _through(table: table, from: from, to: to)
    }

    @discardableResult
    public func through(_ model: (some Model).Type, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: OR throughs.last.table.referenceKey if another through exists!
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(model.idKey).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        return _through(table: model.table, from: from, to: to)
    }
}
