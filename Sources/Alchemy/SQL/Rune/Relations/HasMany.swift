extension Model {
    public typealias HasMany<To: Model> = HasManyRelation<Self, To>

    public func hasMany<To: Model>(db: Database = DB,
                                   _ type: To.Type = To.self,
                                   from fromKey: String? = nil,
                                   to toKey: String? = nil) -> HasMany<To> {
        let from: SQLKey = .infer(Self.idKey).specify(fromKey)
        let to: SQLKey = .infer(Self.referenceKey).specify(toKey)
        return HasMany(db: db, from: self, fromKey: from, toKey: to)
    }
}

public class HasManyRelation<From: Model, M: Model>: Relation<From, [M]> {}
