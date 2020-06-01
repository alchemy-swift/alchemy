import NIO

public protocol Relationship {
    associatedtype From: Model
    associatedtype To: RelationAllowed
    func load(_ from: [From], from eagerLoadKeyPath: KeyPath<From, Self>) -> EventLoopFuture<[From]>
}

class RelationshipDataStorage {
    private static var dict: [String: Any] = [:]
    
    static func store<From: Model, To: RelationAllowed>(
        from: From.Type,
        to: To.Type,
        fromStored: String,
        loadClosure: @escaping EagerLoadClosure<From, To>
    ) {
        let key = "\(From.tableName)_\(To.Value.tableName)_\(fromStored)"
        dict[key] = loadClosure
    }
    
    static func get<From: Model, To: RelationAllowed>(
        from: From.Type,
        to: To.Type,
        fromStored: String
    ) -> EagerLoadClosure<From, To>? {
        let key = "\(From.tableName)_\(To.Value.tableName)_\(fromStored)"
        return dict[key] as? EagerLoadClosure<From, To>
    }
}

typealias EagerLoadClosure<From: Model, To: RelationAllowed> = ([From]) -> EventLoopFuture<[From.Value.Identifier: [To.Value]]>

/// Encapsulates loading behavior from `From` to `To`. Erases any intermediary types.
struct EagerLoader<From: Model, To: RelationAllowed> {
    static func via(
        key: KeyPath<To.Value, To.Value.BelongsTo<From>>,
        keyString: String
    ) -> EagerLoadClosure<From, To> {
        return { from in
            To.Value.query()
                // Should only pull on per id
                .where(key: keyString, in: from.compactMap { $0.id })
                .getAll()
                .flatMapThrowing { Dictionary(grouping: $0, by: { $0[keyPath: key].id! }) }
        }
    }
}
