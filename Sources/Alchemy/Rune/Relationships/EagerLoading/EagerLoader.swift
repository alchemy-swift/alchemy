import NIO

typealias EagerLoadClosure<From: Model, To: RelationAllowed> = ([From]) -> EventLoopFuture<[From.Value.Identifier: [To.Value]]>

/// Encapsulates loading behavior from `From` to `To`. Erases any intermediary types.
struct EagerLoader<From: Model, To: RelationAllowed> {
    static func via(
        key: KeyPath<To.Value, To.Value.BelongsTo<From>>,
        keyString: String
    ) -> EagerLoadClosure<From, To> {
        return { from in
            To.Value.query()
                .where(key: keyString, in: from.compactMap { $0.id })
                .getAll()
                .flatMapThrowing { Dictionary(grouping: $0, by: { $0[keyPath: key].id! }) }
        }
    }
    
    static func through<Through: Model>(
        named: String,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String
    ) -> EagerLoadClosure<From, To> {
        return { from in
            To.Value.query()
                .leftJoin(table: Through.tableName, first: toString, second: "\(To.Value.tableName).id")
                .where(key: fromString, in: from.compactMap { $0.id })
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
