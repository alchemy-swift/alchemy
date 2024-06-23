extension Model {
    public typealias BelongsToThrough<To: ModelOrOptional> = BelongsToThroughRelationship<Self, To>

    public func belongsToThrough<To: Model>(db: Database = To.M.database,
                                            _ through: String,
                                            fromKey: String? = nil,
                                            toKey: String? = nil,
                                            throughFromKey: String? = nil,
                                            throughToKey: String? = nil) -> BelongsToThrough<To> {
        belongsTo(To.self, on: db, from: fromKey, to: toKey)
            .through(through, from: throughFromKey, to: throughToKey)
    }
}

extension BelongsToRelationship {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.BelongsToThrough<To> {
        BelongsToThroughRelationship(belongsTo: self, through: table, fromKey: throughFromKey, toKey: throughToKey)
    }
}

public final class BelongsToThroughRelationship<From: Model, To: ModelOrOptional>: Relationship<From, To> {
    public init(belongsTo: BelongsToRelationship<From, To>, through table: String, fromKey: String?, toKey: String?) {
        super.init(db: belongsTo.db, from: belongsTo.from, fromKey: belongsTo.fromKey, toKey: belongsTo.toKey)
        through(table, from: fromKey, to: toKey)
    }

    public convenience init(db: Database = To.M.database, from: From, _ through: String, fromKey: String? = nil, toKey: String? = nil, throughFromKey: String? = nil, throughToKey: String? = nil) {
        let belongsTo = From.BelongsTo<To>(db: db, from: from, fromKey: fromKey, toKey: toKey)
        self.init(belongsTo: belongsTo, through: through, fromKey: fromKey, toKey: toKey)
    }

    @discardableResult
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        let from: SQLKey = .infer(From.idKey).specify(throughFromKey)
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
        let from: SQLKey = .infer(From.idKey).specify(throughFromKey)
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
