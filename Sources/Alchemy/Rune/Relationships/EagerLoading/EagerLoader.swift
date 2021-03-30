import NIO

/// A closure representing any nested loads to be done after an eager
/// load.
typealias NestedEagerLoadClosure<From: Model, To: ModelMaybeOptional>
    // Param needs to be optional for implicit escaping, otherwise
    // won't compile.
    = ((((ModelQuery<To.Value>) -> ModelQuery<To.Value>)?) -> EagerLoadClosure<From, To>)

/// A closure represnting the input and output of running an eager
/// load.
typealias EagerLoadClosure<From: Model, To: ModelMaybeOptional>
    = ([From]) -> EventLoopFuture<[From.Value.Identifier: [To.Value]]>

/// Encapsulates loading behavior from `From` to `To` for `HasOne` or
/// `HasMany` relationships. Erases any intermediary types.
struct EagerLoader<From: Model, To: ModelMaybeOptional> {
    /// The relationship is loadable by a key on another Model type.
    /// That key holds a reference to this type. Eager loading will
    /// thus load objects of that type with a reference to this
    /// instance's id in that key.
    ///
    /// - Parameters:
    ///   - key: The `KeyPath` on `From` that holds a relationship to
    ///     `To`.
    ///   - keyString: The string name of the table column backing
    ///     `key`.
    ///   - nestedQuery: Any nested query that needs to be run when
    ///     loading this relationship.
    /// - Returns: A closure containing a map of `From` identifiers to
    ///   the array of `To` instances associated with that `From`
    ///   instance, by this relationship.
    static func via(
        key: KeyPath<To.Value, To.Value.BelongsTo<From>>,
        keyString: String,
        nestedQuery: ((ModelQuery<To.Value>) -> ModelQuery<To.Value>)?
    ) -> EagerLoadClosure<From, To> {
        return { from in
            let idsToSearch = from.compactMap { $0.id }.uniques
            guard !idsToSearch.isEmpty else {
                return .new([:])
            }
            
            let initialQuery = To.Value.query()
                .where(key: keyString, in: idsToSearch)
            return (nestedQuery?(initialQuery) ?? initialQuery)
                .allModels()
                .flatMapThrowing { Dictionary(grouping: $0, by: { $0[keyPath: key].id! }) }
        }
    }
    
    /// This eager load occurs through a pivot table, `Through`, with
    /// columns referencing the primary key of both `From` and `To`.
    ///
    /// - Parameters:
    ///   - named: The name of this relationship.
    ///   - fromKey: The `KeyPath` of the reference to the `From` type
    ///     on `Through`.
    ///   - toKey: The `KeyPath` of the reference to the `To` type on
    ///     `Through`.
    ///   - fromString: The name of the column backing the `fromKey`.
    ///   - toString: The name of the column backing the `toKey`.
    ///   - nestedQuery: Any nested queries to run after this eager
    ///     load is finished.
    /// - Returns: A closure containing a map of `From` identifiers to
    ///   the array of `To` instances associated with that `From`
    ///   instance, by this relationship.
    static func through<Through: Model>(
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String,
        nestedQuery: ((ModelQuery<To.Value>) -> ModelQuery<To.Value>)?
    ) -> EagerLoadClosure<From, To> {
        return { from in
            let idsToSearch = from.compactMap { $0.id }.uniques
            guard !idsToSearch.isEmpty else {
                return .new([:])
            }
            
            let initalQuery = To.Value.query()
                .leftJoin(table: Through.tableName, first: toString, second: "\(To.Value.tableName).id")
                .where(key: fromString, in: idsToSearch)
            return (nestedQuery?(initalQuery) ?? initalQuery)
                .get(["\(To.Value.tableName).*, \(fromString)"])
                .flatMapThrowing { toResults in
                    var dict: [From.Value.Identifier: [To.Value]] = [:]
                    for row in toResults {
                        let toVal = try row.decode(To.Value.self)
                        let fromID = try From.Value.Identifier(field: try row.getField(column: fromString))
                        
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
