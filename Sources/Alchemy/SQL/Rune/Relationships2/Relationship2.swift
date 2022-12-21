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

@dynamicMemberLookup
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

    var previous: (any PartialRelationshipQuery<From>)? = nil

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
        let keys = Array(Set(parents.compactMap(\.row?.sqlRow).map(\.[fromKey])))
        let _childRows = try await super.where(toKey, in: keys).getRows()
        var _childModels = try _childRows.mapDecode(To.M.self)

        for load in eagerLoads {
            try await load(&_childModels)
        }

        let _children = zip(_childRows, _childModels)
        var results: [From] = []
        for var parent in parents {
            let from = parent.row?.sqlRow[fromKey]
            let matching = _children.filter { $0.0[toKey] == from }
            parent.row?.eagerLoaded[_hashValue] = matching.map(\.1)
            results.append(parent)
        }

        parents = results
    }

    public func require() throws -> To {
        guard let results = try getEagerLoaded() else {
            throw RuneError("Required relationship from `\(From.self)` to `\(To.self)` wasn't eager loaded!")
        }

        return try To.from(array: results)
    }

    public func fetch() async throws -> To {
        try await To.from(array: get())
    }

    private func getEagerLoaded() throws -> [To.M]? {
        guard let results = from.row?.eagerLoaded[hashValue] else {
            return nil
        }

        guard let castResults = results as? [To.M] else {
            throw RuneError("Eager loading type mismatch!")
        }

        return castResults
    }

    public override func get() async throws -> [To.M] {
        guard let eagerLoaded = try getEagerLoaded() else {
            let key = from.row?.sqlRow[fromKey]
            return try await super
                .where(toKey == key)
                .get()
        }

        return eagerLoaded
    }

    // MARK: @dynamicMemberLookup

    public subscript<T: RelationAllowed>(dynamicMember child: KeyPath<To, To.M.Relationship2<T>>) -> RelationshipQuery<To.M, T> where To.M: EagerLoadable {
        through { $0[keyPath: child] }
    }

    var through: ((From) -> To)?

    func through<T: RelationAllowed>(closure: (To) -> RelationshipQuery<To.M, T>) -> RelationshipQuery<To.M, T> {
        // 0. a closure that...
        // 1. fetches this one
        // 2. maps to the next one
        // 3. when get called, call through (if exists), then fetch

        // **simple things that compose**

        // 0. a composable model query

        // Model Query
        // 1. from -> to
        // 2. from -> to, anonymous throughs
        // 3. from -> to, through

        // Through
        // 1. anonymous no type
        // 2. keypath
    }
}

protocol PartialRelationshipQuery<To> {
    associatedtype To: RelationAllowed

    func fetch() async throws -> To
}

extension RelationshipQuery: PartialRelationshipQuery {

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

            let query = nested(relationship(first))
            try await query.load(for: &results)
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
