extension Model {
    public typealias HasOne<To: ModelOrOptional> = HasOneRelation<Self, To>

    public func hasOne<To: ModelOrOptional>(db: Database = DB,
                                            _ type: To.Type = To.self,
                                            from fromKey: String? = nil,
                                            to toKey: String? = nil) -> HasOne<To> {
        HasOne(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public class HasOneRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    init(db: Database, from: From, fromKey: String?, toKey: String?) {
        let fromKey: SQLKey = .infer(From.idKey).specify(fromKey)
        let toKey: SQLKey = .infer(From.referenceKey).specify(toKey)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
    }
}
