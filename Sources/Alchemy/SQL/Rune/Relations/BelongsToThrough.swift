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
        let from: SQLKey = .infer(From.primaryKey).specify(throughFromKey)
        let to: SQLKey = db.inferReferenceKey(To.M.self).specify(throughToKey)

        let throughReference = db.inferReferenceKey(table)
        if throughs.isEmpty {
            fromKey = fromKey.infer(throughReference.string)
        } else {
            let lastIndex = throughs.count - 1
            throughs[lastIndex].to = throughs[lastIndex].to.infer(throughReference.string)
        }

        return _through(table: table, from: from, to: to)
    }

    @discardableResult
    public func through(_ model: (some Model).Type, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        let from: SQLKey = .infer(From.primaryKey).specify(throughFromKey)
        let to: SQLKey = db.inferReferenceKey(To.M.self).specify(throughToKey)

        let throughReference = db.inferReferenceKey(model)
        if throughs.isEmpty {
            fromKey = fromKey.infer(throughReference.string)
        } else {
            let lastIndex = throughs.count - 1
            throughs[lastIndex].to = throughs[lastIndex].to.infer(throughReference.string)
        }

        return _through(table: model.table, from: from, to: to)
    }
}
