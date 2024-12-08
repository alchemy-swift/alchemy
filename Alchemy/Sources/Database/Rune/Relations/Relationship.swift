public class Relationship<From: Model, To: OneOrMany>: Query<To.M>, EagerLoadable {
    struct Through {
        let table: String
        var from: SQLKey
        var to: SQLKey
    }

    public let from: From
    var fromKey: SQLKey
    var toKey: SQLKey
    var lookupKey: String
    var throughs: [Through]

    /// If set, relationships will be encoded at this key.
    private var encodingKey: String? = nil

    public override var sql: SQL {
        sql(for: [from])
    }

    private func sql(for models: [From]) -> SQL {
        let copy: Query<SQLRow> = convert()
        setJoins(on: copy)
        let fromKeys = models.map(\.row?["\(fromKey)"])
        return copy.`where`(lookupKey, in: fromKeys).sql
    }

    public var cacheKey: CacheKey {
        let key = "\(Self.self)_\(fromKey)_\(toKey)"
        let throughKeys = throughs.map { "\($0.table)_\($0.from)_\($0.to)" }
        let whereKeys = wheres.map { "\($0.hashValue)" }
        return CacheKey(key: ([key] + throughKeys + whereKeys).joined(separator: ":"), encodingKey: encodingKey)
    }

    public init(db: Database, from: From, fromKey: SQLKey, toKey: SQLKey) {
        self.from = from
        self.fromKey = fromKey
        self.toKey = toKey
        self.throughs = []
        self.lookupKey = "\(toKey)"
        super.init(db: db, table: To.M.table, columns: ["\(To.M.table).*"])
    }

    public func fetch(for models: [From]) async throws -> [To] {
        let fromKeys = models.map(\.row?["\(fromKey)"])
        let sql = sql(for: models)
        let rows = try await db.query(sql: sql, logging: logging)
        let results = try await _didLoad(rows.map(To.M.init))
        let resultsByLookup = results.grouped(by: \.row?[lookupKey])
        return try fromKeys
            .map { resultsByLookup[$0, default: []] }
            .map { try To(models: $0) }
    }

    private func setJoins<Result: QueryResult>(on query: Query<Result>) {
        guard let table else {
            preconditionFailure("Table required to run a query - don't manually override the one set by `Relation`.")
        }

        var nextKey = "\(table).\(toKey)"
        for through in throughs.reversed() {
            query.join(table: through.table, first: "\(through.table).\(through.to)", second: nextKey)
            nextKey = "\(through.table).\(through.from)"
        }
    }

    @discardableResult
    func _through(table: String, from: SQLKey, to: SQLKey) -> Self {
        if throughs.isEmpty {
            lookupKey = "\(table).\(from)"
            columns.append("\(lookupKey) as \(lookupKey.inQuotes)")
        }

        throughs.append(Through(table: table, from: from, to: to))
        return self
    }

    func requireFromValue() throws -> SQLValue {
        guard let value = from.row?["\(fromKey)"] else {
            throw RuneError("Missing key `\(fromKey)` on `\(From.self)`.")
        }

        return value
    }

    func requireToValue<M: Model>(_ model: M) throws -> SQLValue {
        guard let value = model.row?["\(toKey)"] else {
            throw RuneError("Missing key `\(toKey)` on `\(M.self)`.")
        }

        return value
    }

    public func key(_ key: String) -> Self {
        self.encodingKey = key
        return self
    }
}
