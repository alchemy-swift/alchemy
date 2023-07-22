extension Model {
    public typealias BelongsTo<To: ModelOrOptional> = BelongsToRelation<Self, To>

    public func belongsTo<To: ModelOrOptional>(db: Database = DB,
                                               _ type: To.Type = To.self,
                                               from fromKey: String? = nil,
                                               to toKey: String? = nil) -> BelongsTo<To> {
        let from: SQLKey = .infer(To.M.referenceKey).specify(fromKey)
        let to: SQLKey = .infer(To.M.idKey).specify(toKey)
        return BelongsTo(db: db, from: self, fromKey: from, toKey: to)
    }
}

public class BelongsToRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {}
