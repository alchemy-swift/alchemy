extension Model {
    public typealias HasMany<To: Model> = HasManyRelation<Self, To>

    public func hasMany<To: Model>(_ type: To.Type = To.self,
                                   db: Database = DB,
                                   from fromKey: String? = nil,
                                   to toKey: String? = nil) -> HasMany<To> {
        HasMany(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public class HasManyRelation<From: Model, M: Model>: Relation<From, [M]> {
    init(db: Database, from: From, fromKey: String?, toKey: String?) {
        let fromKey: SQLKey = .infer(From.idKey).specify(fromKey)
        let toKey: SQLKey = .infer(From.referenceKey).specify(toKey)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
    }
}
