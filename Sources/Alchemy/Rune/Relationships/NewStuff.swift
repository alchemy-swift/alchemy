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
    var from: KeyStrings
    var to: KeyStrings
    
    var through: RelationConfig?
    
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
    public func through(_ table: String, config: ((RelationConfig) -> Void)? = nil) -> RelationConfig {
        let rel = RelationConfig(
            from: KeyStrings(
                table: table,
                keyDefault: from.keyDefault
            ),
            to: KeyStrings(
                table: to.table,
                keyDefault: to.keyDefault,
                keyOverride: "id"
            )
        )
        config?(rel)
        through = rel
        return rel
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
        var whereTable = to.table
        if let through = through {
            whereTable = through.from.table
            query = query.leftJoin(table: through.from.table, first: "\(through.from.table).\(through.from.key)", second: "\(through.to.table).\(through.to.key)")
        }

        let ids = values.map { try! $0.getField(column: from.key).value }
        query = query.where(key: "\(whereTable).\(to.key)", in: ids)
        return query
    }
}

extension Model {
    static var referenceKey: String {
        let key = name(of: Self.self) + "Id"
        return keyMapping.map(input: key)
    }
}
