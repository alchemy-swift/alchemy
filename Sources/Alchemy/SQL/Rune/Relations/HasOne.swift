extension Model {
    public typealias HasOne<To: ModelOrOptional> = HasOneRelation<Self, To>

    public func hasOne<To: ModelOrOptional>(_ type: To.Type = To.self,
                                            db: Database = DB,
                                            from fromKey: String? = nil,
                                            to toKey: String? = nil) -> HasOne<To> {
        HasOne(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public class HasOneRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    init(db: Database, from: From, fromKey: String?, toKey: String?) {
        let fromKey: SQLKey = .infer(From.primaryKey).specify(fromKey)
        let toKey: SQLKey = db.inferReferenceKey(From.self).specify(toKey)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
    }

    public func connect(_ model: To.M) async throws {
        let value = try requireFromValue()
        try await model.update(["\(toKey)": value])
    }

    public func replace(_ model: To.M) async throws {
        try await _disconnect()
        try await connect(model)
    }

    public func disconnect<M: Model>() async throws where To == Optional<M> {
        try await _disconnect()
    }

    /// Private so this will only be exposed if the relationship is optional.
    private func _disconnect() async throws {
        let value = try requireFromValue()
        let existing = try await To.M.`where`("\(toKey)" == value).first()
        try await existing?.update(["\(toKey)": SQLValue.null])
    }
}
