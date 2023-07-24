extension Model {
    public typealias BelongsToThrough<To: ModelOrOptional> = BelongsToThroughRelation<Self, To>
}

extension BelongsToRelation {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.BelongsToThrough<To> {
        BelongsToThroughRelation(belongsTo: self, through: table, fromKey: throughFromKey, toKey: throughToKey)
    }
}

public final class BelongsToThroughRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    init(belongsTo: BelongsToRelation<From, To>, through table: String, fromKey: String?, toKey: String?) {
        super.init(db: belongsTo.db, from: belongsTo.from, fromKey: belongsTo.fromKey, toKey: belongsTo.toKey)
        through(table, from: fromKey, to: toKey)
    }

    @discardableResult
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: FIX FOR BELONGS
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(db.keyMapping.encode("Id")).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        return _through(table: table, from: from, to: to)
    }

    @discardableResult
    public func through(_ model: (some Model).Type, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: FIX FOR BELONGS
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(model.idKey).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        return _through(table: model.table, from: from, to: to)
    }
}
