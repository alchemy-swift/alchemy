extension Model {
    public typealias BelongsTo<To: ModelOrOptional> = BelongsToRelation<Self, To>

    public func belongsTo<To: ModelOrOptional>(db: Database = DB,
                                               _ type: To.Type = To.self,
                                               from fromKey: String? = nil,
                                               to toKey: String? = nil) -> BelongsTo<To> {
        BelongsTo(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public class BelongsToRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    init(db: Database, from: From, fromKey: String?, toKey: String?) {
        let fromKey: SQLKey = .infer(To.M.referenceKey).specify(fromKey)
        let toKey: SQLKey = .infer(To.M.idKey).specify(toKey)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
    }
}
