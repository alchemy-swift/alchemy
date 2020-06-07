import NIO

typealias NestedEagerLoadClosure<From: Model, To: RelationAllowed>
    // Param needs to be optional for implicit escaping, otherwise won't compile.
    = ((((ModelQuery<To.Value>) -> ModelQuery<To.Value>)?) -> EagerLoadClosure<From, To>)

typealias EagerLoadClosure<From: Model, To: RelationAllowed>
    = ([From]) -> EventLoopFuture<[From.Value.Identifier: [To.Value]]>

/// Encapsulates loading behavior from `From` to `To` for `HasOne` or `HasMany` relationships. Erases any
/// intermediary types.
struct EagerLoader<From: Model, To: RelationAllowed> {
    static func via(
        key: KeyPath<To.Value, To.Value.BelongsTo<From>>,
        keyString: String,
        nestedQuery: ((ModelQuery<To.Value>) -> ModelQuery<To.Value>)?
    ) -> EagerLoadClosure<From, To> {
        return { from in
            let idsToSearch = from.compactMap { $0.id }.uniques
            let initialQuery = To.Value.query()
                .where(key: keyString, in: idsToSearch)
            return (nestedQuery?(initialQuery) ?? initialQuery)
                .getAll()
                .flatMapThrowing { Dictionary(grouping: $0, by: { $0[keyPath: key].id! }) }
        }
    }
    
    static func through<Through: Model>(
        named: String,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String,
        /// TODO: This doesn't work, yet.
        nestedQuery: ((ModelQuery<To.Value>) -> ModelQuery<To.Value>)?
    ) -> EagerLoadClosure<From, To> {
        return { from in
            let idsToSearch = from.compactMap { $0.id }.uniques
            let initalQuery = To.Value.query()
                .leftJoin(table: Through.tableName, first: toString, second: "\(To.Value.tableName).id")
                .where(key: fromString, in: idsToSearch)
            return (nestedQuery?(initalQuery) ?? initalQuery)
                .get(["\(To.Value.tableName).*, \(fromString)"])
                .flatMapThrowing { toResults in
                    var dict: [From.Value.Identifier: [To.Value]] = [:]
                    for row in toResults {
                        let toVal = try row.decode(To.Value.self)
                        let fromID = try From.Value.Identifier.from(field: try row.getField(columnName: fromString))
                        
                        if let array = dict[fromID] {
                            dict[fromID] = array + [toVal]
                        } else {
                            dict[fromID] = [toVal]
                        }
                    }
                    return dict
                }
        }
    }
}
