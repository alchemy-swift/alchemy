public final class RelationMapper<M: Model> {
    private var configs: [PartialKeyPath<M>: RelationConfig] = [:]
    
    public func config<R: Relationship>(for relation: KeyPath<M, R>) -> RelationConfig {
        if let rel = configs[relation] {
            return rel
        } else {
            return R.defaultConfig()
        }
    }
    
    public func relate<R: Relationship>(_ keyPath: KeyPath<M, R>) -> RelationConfig {
        let rel = R.defaultConfig()
        configs[keyPath] = rel
        return rel
    }
    
    init() {}
}

struct KeyStrings {
    var table: String
    let keyDefault: String
    var keyOverride: String?
    var key: String { keyOverride ?? keyDefault }
}

public final class RelationConfig {
    struct Through {
        let table: String
        let left: String
        let right: String
    }
    
    var from: KeyStrings
    var to: KeyStrings
    var through: Through?
    
    // The key to index results by for matching with from models.
    var indexKey: String { through?.right ?? to.key }
    
    init(from: KeyStrings, to: KeyStrings) {
        self.from = from
        self.to = to
    }
    
    @discardableResult
    public func from(_ key: String) -> Self {
        self.from.keyOverride = key
        return self
    }
    
    @discardableResult
    public func to(_ key: String) -> Self {
        self.to.keyOverride = key
        return self
    }
    
    @discardableResult
    public func through(_ table: String, left: String? = nil, right: String? = nil) -> RelationConfig {
        let left = left ?? from.keyDefault
        let right = right ?? to.keyDefault
        
        // Assume each local key is `id`, unless already set.
        if from.keyOverride == nil {
            from.keyOverride = "id"
        }
        
        if to.keyOverride == nil {
            to.keyOverride = "id"
        }
        
        through = Through(table: table, left: left, right: right)
        return self
    }
}

extension RelationConfig {
    static func defaultHas<From: Model, To: Model>(from: From.Type, to: To.Type) -> RelationConfig {
        RelationConfig(
            from: KeyStrings(
                table: From.tableName,
                keyDefault: To.Value.referenceKey,
                keyOverride: "id"
            ),
            to: KeyStrings(
                table: To.Value.tableName,
                keyDefault: From.referenceKey
            )
        )
    }
    
    static func defaultBelongsTo<From: Model, To: Model>(from: From.Type, to: To.Type) -> RelationConfig {
        RelationConfig(
            from: KeyStrings(
                table: From.tableName,
                keyDefault: To.Value.referenceKey
            ),
            to: KeyStrings(
                table: To.Value.tableName,
                keyDefault: From.referenceKey,
                keyOverride: "id"
            )
        )
    }
}

extension RelationConfig {
    func load<M: Model>(_ values: [DatabaseRow]) -> ModelQuery<M> {
        var query = M.query().from(table: to.table)
        var whereKey = "\(to.table).\(to.key)"
        if let through = through {
            whereKey = "\(through.table).\(through.right)"
            query = query.leftJoin(table: through.table, first: "\(through.table).\(through.left)", second: "\(to.table).\(to.key)")
        }

        let ids = values.map { try! $0.getField(column: from.key).value }
        query = query.where(key: "\(whereKey)", in: ids)
        return query
    }
}

extension Model {
    static var referenceKey: String {
        let key = name(of: Self.self) + "Id"
        return keyMapping.map(input: key)
    }
}
