public class Relation<From: Model, To: OneOrMany>: Query<To.M>, EagerLoadable {
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

    public var cacheKey: String {
        let key = "\(name(of: Self.self))_\(fromKey)_\(toKey)"
        let throughKeys = throughs.map { "\($0.table)_\($0.from)_\($0.to)" }
        let whereKeys = wheres.map { "\($0.hashValue)" }
        return ([key] + throughKeys + whereKeys).joined(separator: ":")
    }

    public init(db: Database, from: From, fromKey: SQLKey, toKey: SQLKey) {
        self.from = from
        self.fromKey = fromKey
        self.toKey = toKey
        self.throughs = []
        self.lookupKey = "\(toKey)"
        super.init(db: db, table: To.M.table)
    }

    public func fetch(for models: [From]) async throws -> [To] {
        setJoins()
        let fromKeys = models.map(\.row["\(fromKey)"])
        let results = try await `where`(lookupKey, in: fromKeys).get(columns)
        let resultsByLookup = results.grouped(by: \.row[lookupKey])
        return try fromKeys
            .map { resultsByLookup[$0, default: []] }
            .map { try To(models: $0) }
    }

    private func setJoins() {
        var nextKey = "\(table).\(toKey)"
        for through in throughs.reversed() {
            join(table: through.table, first: "\(through.table).\(through.to)", second: nextKey)
            nextKey = "\(through.table).\(through.from)"
        }
    }

    @discardableResult
    func _through(table: String, from: SQLKey, to: SQLKey) -> Self {
        if throughs.isEmpty {
            lookupKey = "\(table).\(from)"
            columns.append("\(lookupKey) as \"\(lookupKey)\"")
        }

        throughs.append(Through(table: table, from: from, to: to))
        return self
    }

    func requireFromValue() throws -> SQLValue {
        guard let value = from.row["\(fromKey)"] else {
            throw RuneError("Missing key `\(fromKey)` on `\(From.self)`.")
        }

        return value
    }

    func requireToValue<M: Model>(_ model: M) throws -> SQLValue {
        guard let value = model.row["\(toKey)"] else {
            throw RuneError("Missing key `\(toKey)` on `\(M.self)`.")
        }

        return value
    }
}
