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
        let fromKey: SQLKey = .infer(From.primaryKey).specify(fromKey)
        let toKey: SQLKey = db.inferReferenceKey(From.self).specify(toKey)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
    }

    public func connect(_ model: M) async throws {
        try await connect([model])
    }

    public func connect(_ models: [M]) async throws {
        let value = try requireFromValue()
        try await models.updateAll(["\(toKey)": value])
    }

    public func replace(_ models: [M]) async throws {
        try await disconnectAll()
        try await connect(models)
    }

    public func disconnect(_ model: M) async throws {
        try await model.update(["\(toKey)": SQLValue.null])
    }

    public func disconnectAll() async throws {
        let value = try requireFromValue()
        try await To.M.`where`("\(toKey)" == value).update(["\(toKey)": .null])
    }
}
