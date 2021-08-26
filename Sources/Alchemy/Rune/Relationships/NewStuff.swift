public final class RelationMapper<M: Model> {
    private var configs: [PartialKeyPath<M>: AnyRelation] = [:]
    
    init() {}
    
    func config<R: Relationship>(for relation: KeyPath<M, R>) -> Relation<R.From, R.To.Value> {
        if let rel = configs[relation] {
            return rel as! Relation<R.From, R.To.Value>
        } else {
            return R.defaultConfig()
        }
    }
    
    public func relate<R: Relationship>(_ keyPath: KeyPath<M, R>) -> Relation<R.From, R.To.Value> {
        let rel = R.defaultConfig()
        configs[keyPath] = rel
        return rel
    }
}

// 2 keys on the same row
struct Through {
    var table: String
    var fromKey: String
    var toKey: String
}

struct Keys {
    // This table i.e. `users`
    let table: String
    // This table's local key i.e. `id`
    let local: String
    // A foreign key referencing this table i.e. `user_id`
    let foreign: String
    
    init<T: Model>(_ type: T.Type) {
        self.table = T.tableName
        self.local = "id"
        self.foreign = T.referenceKey
    }
}

struct KeyStrings {
    var table: String
    let keyDefault: String
    var keyOverride: String?
    var key: String { keyOverride ?? keyDefault }
}

protocol AnyRelation {}

enum RelationType {
    case has, belongs
}

public final class Relation<From: Model, To: Model>: AnyRelation {
    var fromTable: String
    var fromKeyAssumed: String
    var fromKeyOverride: String?
    var fromKey: String { fromKeyOverride ?? fromKeyAssumed }
    var toTable: String
    var toKeyAssumed: String
    var toKeyOverride: String?
    var toKey: String { toKeyOverride ?? toKeyAssumed }
    var type: RelationType
    
    var through: Through? {
        didSet {
            if oldValue != nil && through != nil {
                fatalError("For now, only one through is allowed per relation.")
            }
        }
    }

    var fromJoinKey: String { fromKey }
    var toJoinKey: String { through?.fromKey ?? toKey }
    
    internal init(
        _ type: RelationType,
        fromTable: String = From.tableName,
        fromKey: String = To.referenceKey,
        toTable: String = To.tableName,
        toKey: String = From.referenceKey
    ) {
        self.type = type
        self.fromTable = fromTable
        self.fromKeyAssumed = fromKey
        self.toTable = toTable
        self.toKeyAssumed = toKey
    }
    
    @discardableResult
    public func from(_ key: String) -> Self {
        self.fromKeyOverride = key
        return self
    }
    
    @discardableResult
    public func to(_ key: String) -> Self {
        self.toKeyOverride = key
        return self
    }
    
    // Shouldn't be available on `BelongsTo`?
    @discardableResult
    public func throughPivot(_ table: String, from: String = From.referenceKey, to: String = To.referenceKey) -> Self {
        fromKeyAssumed = "id"
        toKeyAssumed = "id"
        through = Through(table: table, fromKey: from, toKey: to)
        return self
    }
    
    @discardableResult
    public func through(_ table: String, from: String? = nil, to: String? = nil) -> Self {
        let tableReference = From.keyMapping.map(input: table.singularized + "Id")
        let _from, _to: String
        switch type {
        case .belongs:
            _from = from ?? "id"
            _to = to ?? To.referenceKey
            fromKeyAssumed = tableReference
        case .has:
            _from = from ?? From.referenceKey
            _to = to ?? "id"
            toKeyAssumed = tableReference
        }
        through = Through(table: table, fromKey: _from, toKey: _to)
        return self
    }
}

extension Relation {
    static func defaultHas() -> Relation<From, To> {
        Relation(.has, fromKey: "id")
    }
    
    static func defaultBelongsTo() -> Relation<From, To> {
        Relation(.belongs, toKey: "id")
    }
}

extension Relation {
    func load<M: Model>(_ values: [DatabaseRow]) throws -> ModelQuery<M> {
        var query = M.query().from(table: toTable)
        var whereKey = "\(toTable).\(toKey)"
        if let through = through {
            whereKey = "\(through.table).\(through.fromKey)"
            query = query.leftJoin(table: through.table, first: "\(through.table).\(through.toKey)", second: "\(toTable).\(toKey)")
        }

        print("from key: \(fromKey)")
        let ids = try values.map { try $0.getField(column: fromKey).value }
        query = query.where(key: "\(whereKey)", in: ids)
        return query
    }
}

extension Model {
    public static var referenceKey: String {
        let key = name(of: Self.self) + "Id"
        return keyMapping.map(input: key)
    }
}
