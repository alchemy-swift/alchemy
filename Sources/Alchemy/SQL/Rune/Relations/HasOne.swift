extension Model {
    public typealias HasOne<To: ModelOrOptional> = HasOneRelation<Self, To>

    public func hasOne<To: ModelOrOptional>(db: Database = DB,
                                            _ type: To.Type = To.self,
                                            from fromKey: String? = nil,
                                            to toKey: String? = nil) -> HasOne<To> {
        let from: SQLKey = .infer(Self.idKey).specify(fromKey)
        let to: SQLKey = .infer(Self.referenceKey).specify(toKey)
        return HasOne(db: db, from: self, fromKey: from, toKey: to)
    }
}

public class HasOneRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {}
