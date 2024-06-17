import Collections

extension Model {
    public typealias BelongsToMany<To: Model> = BelongsToManyRelation<Self, To>

    public func belongsToMany<To: ModelOrOptional>(_ type: To.Type = To.self,
                                                   on db: Database = To.M.database,
                                                   from fromKey: String? = nil,
                                                   to toKey: String? = nil,
                                                   pivot: String? = nil,
                                                   pivotFrom: String? = nil,
                                                   pivotTo: String? = nil) -> BelongsToMany<To> {
        BelongsToMany(db: db, from: self, fromKey: fromKey, toKey: toKey, pivot: pivot, pivotFrom: pivotFrom, pivotTo: pivotTo)
    }
}

public class BelongsToManyRelation<From: Model, M: Model>: Relation<From, [M]> {
    private var pivot: Through {
        guard let pivot = throughs.first else { preconditionFailure("BelongsToManyRelation must never have no throughs.") }
        return pivot
    }

    init(db: Database, from: From, fromKey: String?, toKey: String?, pivot: String?, pivotFrom: String?, pivotTo: String?) {
        let fromKey: SQLKey = .infer(From.primaryKey).specify(fromKey)
        let toKey: SQLKey = .infer(M.primaryKey).specify(toKey)
        let pivot: String = pivot ?? From.table.singularized + "_" + M.table.singularized
        let pivotFrom: SQLKey = db.inferReferenceKey(From.self).specify(pivotFrom)
        let pivotTo: SQLKey = db.inferReferenceKey(M.self).specify(pivotTo)
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
        _through(table: pivot, from: pivotFrom, to: pivotTo)
    }

    public func connect(_ model: M, pivotFields: SQLFields = [:]) async throws {
        try await connect([model], pivotFields: pivotFields)
    }

    public func connect(_ models: [M], pivotFields: SQLFields = [:]) async throws {
        let from = try requireFromValue()
        let tos = try models.map { try requireToValue($0) }
        guard fromKey.string != toKey.string else {
            throw DatabaseError("Pivot table can't have duplicate keys")
        }

        let fieldsArray = tos.map { ["\(fromKey)": from, "\(toKey)": $0] + pivotFields }
        try await db.table(pivot.table).insert(fieldsArray)
    }

    public func connectOrUpdate(_ model: M, pivotFields: SQLFields = [:]) async throws {
        try await connectOrUpdate([model], pivotFields: pivotFields)
    }

    public func connectOrUpdate(_ models: [M], pivotFields: SQLFields = [:]) async throws {
        let from = try requireFromValue()
        let tos = try models.map { try (requireToValue($0), $0) }

        // 0. Get existing
        let existing = try await db.table(pivot.table)
            .where("\(fromKey)" == from)
            .where("\(toKey)", in: tos.map(\.0))
            .select("\(toKey)")
            .get()
        let existingToKeys = existing.compactMap(\.["\(toKey)"])

        // 1. Update existing
        try await db.table(pivot.table)
            .where("\(fromKey)" == from)
            .where("\(toKey)", in: existingToKeys)
            .update(pivotFields)

        // 2. Insert new
        let notExisting = tos.filter { !existingToKeys.contains($0.0) }.map(\.1)
        try await connect(notExisting, pivotFields: pivotFields)
    }

    public func replace(_ models: [M], pivotFields: SQLFields = [:]) async throws {
        try await disconnectAll()
        try await connect(models, pivotFields: pivotFields)
    }

    public func disconnect(_ model: M) async throws {
        let from = try requireFromValue()
        let to = try requireToValue(model)
        try await db.table(pivot.table)
            .where("\(toKey)" == to)
            .where("\(fromKey)" == from)
            .delete()
    }

    public func disconnectAll() async throws {
        let from = try requireFromValue()
        try await db.table(pivot.table)
            .where("\(fromKey)" == from)
            .delete()
    }
}
