extension Model {
    public typealias BelongsToMany<To: Model> = BelongsToManyRelation<Self, To>

    public func belongsToMany<To: ModelOrOptional>(_ type: To.Type = To.self,
                                                   db: Database = DB,
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
        let fromKey: SQLKey = .infer(From.primaryKey).specify(fromKey)
        let toKey: SQLKey = .infer(M.primaryKey).specify(toKey)
        let pivot: String = pivot ?? From.table.singularized + "_" + M.table.singularized
        let pivotFrom: SQLKey = db.inferReferenceKey(From.self).specify(pivotFrom)
        let pivotTo: SQLKey = db.inferReferenceKey(M.self).specify(pivotTo)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
        _through(table: pivot, from: pivotFrom, to: pivotTo)
    }

    /*
     4. (M-M) `BelongsToMany`

     - `connect`: associate with a new value(s) (+ keys for intermediary)
     - `connectOrUpdate`: adds or updates any new connections (+ keys for intermediary)
     - `replace`: set the results, remove all others (+ keys for intermediary)
     - `disconnect`: delete intermediary entry
     - `disconnectAll`: delete all intermediary entries
     */
}
