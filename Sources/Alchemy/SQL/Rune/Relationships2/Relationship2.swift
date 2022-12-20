public protocol EagerLoadable where Self: Model {
    var row: ModelRow? { get set }
}

public struct ModelRow: ModelProperty, Codable {
    public let sqlRow: SQLRow
    public var eagerLoaded: [Int: [any Model]]

    // MARK: Codable

    public init(from decoder: Decoder) throws {
        self.sqlRow = SQLRow(fields: [])
        self.eagerLoaded = [:]
    }

    public func encode(to encoder: Encoder) throws {
    }

    // MARK: ModelProperty

    public init(key: String, on row: SQLRowReader) throws {
        self.sqlRow = row.row
        self.eagerLoaded = [:]
    }

    public func store(key: String, on row: inout SQLRowWriter) throws {
        // Do nothing
    }
}

public class RelationshipQuery<From: EagerLoadable, To: RelationAllowed>: Query<To.M>, Hashable {
    struct Through: Hashable {
        let table: String
        let fromKey: String
        let toKey: String

        func hash(into hasher: inout Swift.Hasher) {
            hasher.combine(table)
            hasher.combine(fromKey)
            hasher.combine(toKey)
        }
    }

    var from: From
    var fromKey: String
    var toKey: String
    var throughs: [Through]

    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(From.tableName)
        hasher.combine(To.M.tableName)
        hasher.combine(fromKey)
        hasher.combine(toKey)
        hasher.combine(throughs)
        hasher.combine(wheres)
    }

    init(db: Database = DB, from: From, fromKey: String, toKey: String) {
        self.from = from
        self.fromKey = fromKey
        self.toKey = toKey
        self.throughs = []
        super.init(db: db)
    }

    func through(_ table: String, from fromKey: String, to toKey: String) -> Self {
        throughs.append(Through(table: table, fromKey: fromKey, toKey: toKey))
        return self
    }

    func load(for parents: inout [From]) async throws {
        let _hashValue = hashValue
        let _results = try await _get(parents).map(\.1)
        var results: [From] = []
        for var parent in parents {
            let from = parent.row?.sqlRow[fromKey]
            let matching = _results.filter { $0[toKey] == from }
            let decoded = try matching.map { try $0.decode(To.M.self) }
            parent.row?.eagerLoaded[_hashValue] = decoded
            results.append(parent)
        }

        parents = results
    }

    public func fetch() async throws -> To {
        try await To.from(array: get())
    }

    public override func get() async throws -> [To.M] {
        guard let results = from.row?.eagerLoaded[hashValue] else {
            return try await _get([from]).map(\.0)
        }

        guard let castResults = results as? [To.M] else {
            throw RuneError("Eager loading type mismatch!")
        }

        return castResults
    }

    private func _get(_ parents: [From]) async throws -> [(To.M, SQLRow)] {
        guard !parents.isEmpty else {
            return []
        }

        let parentKeys = parents.compactMap(\.row?.sqlRow).map(\.[fromKey])
        return try await self
            .where(toKey, in: parentKeys)
            .log()
            .getRows()
            .map { (try $0.decode(To.M.self), $0) }
    }
}

extension Query where M: EagerLoadable {
    public func with<To: RelationAllowed>(
        _ relationship: @escaping (M) -> M.Relationship2<To>,
        nested: @escaping ((M.Relationship2<To>) -> M.Relationship2<To>) = { $0 }
    ) -> Self {
        let load: (inout [M]) async throws -> Void = { results in
            guard let first = results.first else {
                return
            }

            // Get the relationship from the first model.
            let relationship = relationship(first)
            try await nested(relationship).load(for: &results)
        }

        eagerLoads.append(load)
        return self
    }
}

extension EagerLoadable {
    public typealias Relationship2<To: RelationAllowed> = RelationshipQuery<Self, To>

    public func hasMany<To: Model>(from fromKey: String = Self.idKey, to toKey: String = Self.referenceKey) -> Relationship2<[To]> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey)
    }

    public func hasOne<To: Model>(from fromKey: String = Self.idKey, to toKey: String = Self.referenceKey) -> Relationship2<To> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey)
    }

    public func belongsTo<To: Model>(from fromKey: String = To.referenceKey, to toKey: String = To.idKey) -> Relationship2<To> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public protocol RelationAllowed {
    associatedtype M: Model

    static func from(array: [M]) throws -> Self
}

extension Array: RelationAllowed where Element: Model {
    public typealias M = Element

    public static func from(array: [Element]) throws -> [M] {
        array
    }
}

extension Optional: RelationAllowed where Wrapped: Model {
    public typealias M = Wrapped

    public static func from(array: [Wrapped]) throws -> Wrapped? {
        array.first
    }
}
