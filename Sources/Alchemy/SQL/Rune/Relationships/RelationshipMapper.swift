/// Associates Relationships with their mapping.
public final class RelationshipMapper<M: Model> {
    private var configs: [PartialKeyPath<M>: AnyRelation] = [:]
    
    init() {}
    
    public func config<R: Relationship>(_ keyPath: KeyPath<M, R>) -> RelationshipMapping<R.From, R.To.Value> {
        let rel = R.defaultConfig()
        configs[keyPath] = rel
        return rel
    }
    
    func getConfig<R: Relationship>(for relation: KeyPath<M, R>) -> RelationshipMapping<R.From, R.To.Value> {
        if let rel = configs[relation] {
            return rel as! RelationshipMapping<R.From, R.To.Value>
        } else {
            return R.defaultConfig()
        }
    }
}

protocol AnyRelation {}

/// Defines how a `Relationship` is mapped from it's `From` to `To`.
public final class RelationshipMapping<From: Model, To: Model>: AnyRelation {
    enum Kind {
        case has, belongs
    }
    
    struct Through {
        var table: String
        var fromKey: String
        var toKey: String
    }
    
    var fromTable: String
    var fromKeyAssumed: String
    var fromKeyOverride: String?
    var fromKey: String { fromKeyOverride ?? fromKeyAssumed }
    var toTable: String
    var toKeyAssumed: String
    var toKeyOverride: String?
    var toKey: String { toKeyOverride ?? toKeyAssumed }
    var type: Kind
    
    var through: Through? {
        didSet {
            if oldValue != nil && through != nil {
                fatalError("For now, only one through is allowed per relation.")
            }
        }
    }

    init(
        _ type: Kind,
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

extension RelationshipMapping {
    static func defaultHas() -> RelationshipMapping<From, To> {
        RelationshipMapping(.has, fromKey: "id")
    }
    
    static func defaultBelongsTo() -> RelationshipMapping<From, To> {
        RelationshipMapping(.belongs, toKey: "id")
    }
}

extension Model {
    public static var referenceKey: String {
        let key = name(of: Self.self) + "Id"
        return keyMapping.map(input: key)
    }
}
