public class ThroughRelation<From: Model, To: OneOrMany>: Relation<From, To> {
    private var throughs: [Through] = []

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    public override func fetch(for models: [From]) async throws -> [To] {
        setJoins()
        let lookupKey = "\(throughs.first!.table).\(throughs.first!.from)"
        let columns = ["\(table).*", lookupKey]
        let keys = models.map(\.row["\(fromKey)"])
        let results = try await `where`(lookupKey, in: keys).get(columns)
        let resultsByLookup = results.grouped(by: \.row[lookupKey])
        return try keys
            .map { resultsByLookup[$0] ?? [] }
            .map { try To(models: $0) }
    }

    private func setJoins() {
        var nextKey = "\(table).\(toKey)"
        for through in throughs.reversed() {
            join(table: through.table, first: "\(through.table).\(through.to)", second: nextKey)
            nextKey = "\(through.table).\(through.from)"
        }
    }

    func _through(table: String, from: SQLKey, to: SQLKey) -> Self {
        throughs.append(Through(table: table, from: from, to: to))
        return self
    }
}

struct Through {
    let table: String
    let from: SQLKey
    let to: SQLKey
}
