extension Model {
    public typealias HasOne<To: ModelOrOptional> = HasOneRelationship<Self, To>

    public func hasOne<To: ModelOrOptional>(_ type: To.Type = To.self,
                                            on db: Database = To.M.database,
                                            from fromKey: String? = nil,
                                            to toKey: String? = nil) -> HasOne<To> {
        HasOne(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public class HasOneRelationship<From: Model, To: ModelOrOptional>: Relationship<From, To> {
    public init(db: Database = To.M.database, from: From, fromKey: String? = nil, toKey: String? = nil) {
        let fromKey: SQLKey = .infer(From.idKey).specify(fromKey)
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
        try await existing?.update(["\(toKey)": .null])
    }
}
