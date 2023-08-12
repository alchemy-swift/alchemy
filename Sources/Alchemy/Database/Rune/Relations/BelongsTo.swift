extension Model {
    public typealias BelongsTo<To: ModelOrOptional> = BelongsToRelation<Self, To>

    public func belongsTo<To: ModelOrOptional>(_ type: To.Type = To.self,
                                               on db: Database = To.M.database,
                                               from fromKey: String? = nil,
                                               to toKey: String? = nil) -> BelongsTo<To> {
        BelongsTo(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public class BelongsToRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    init(db: Database, from: From, fromKey: String?, toKey: String?) {
        let fromKey: SQLKey = db.inferReferenceKey(To.M.self).specify(fromKey)
        let toKey: SQLKey = .infer(To.M.primaryKey).specify(toKey)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
    }

    public func connect(_ model: To.M) async throws {
        let value = try requireToValue(model)
        try await from.update(["\(fromKey)": value])
    }

    public func disconnect<M: Model>() async throws where To == Optional<M> {
        try await from.update(["\(fromKey)": SQLValue.null])
    }
}
