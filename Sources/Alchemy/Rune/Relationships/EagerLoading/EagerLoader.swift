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
                // Should only pull on per id
                .where(key: keyString, in: from.compactMap { $0.id })
                .getAll()
                .flatMapThrowing { Dictionary(grouping: $0, by: { $0[keyPath: key].id! }) }
        }
    }
}
