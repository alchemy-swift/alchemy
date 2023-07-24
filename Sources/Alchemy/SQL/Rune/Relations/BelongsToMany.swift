extension Model {
    public typealias BelongsToMany<To: Model> = BelongsToManyRelation<Self, To>

    public func belongsToMany<To: ModelOrOptional>(db: Database = DB,
                                                   _ type: To.Type = To.self,
                                                   from fromKey: String? = nil,
                                                   to toKey: String? = nil,
                                                   pivot: String? = nil,
                                                   pivotFrom: String? = nil,
                                                   pivotTo: String? = nil) -> BelongsToMany<To> {
        BelongsToMany(db: db, from: self, fromKey: fromKey, toKey: toKey, pivot: pivot, pivotFrom: pivotFrom, pivotTo: pivotTo)
    }
}

public class BelongsToManyRelation<From: Model, M: Model>: Relation<From, [M]> {
    init(db: Database, from: From, fromKey: String?, toKey: String?, pivot: String?, pivotFrom: String?, pivotTo: String?) {
        let fromKey: SQLKey = .infer(From.idKey).specify(fromKey)
        let toKey: SQLKey = .infer(M.idKey).specify(toKey)
        let pivot: String = pivot ?? From.table.singularized + "_" + M.table.singularized
        let pivotFrom: SQLKey = .infer(From.referenceKey).specify(pivotFrom)
        let pivotTo: SQLKey = .infer(M.referenceKey).specify(pivotTo)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
        _through(table: pivot, from: pivotFrom, to: pivotTo)
    }
}
