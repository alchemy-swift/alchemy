import Foundation
import NIO

public class ModelQuery<M: Model>: Query {
    private var eagerLoads: [([M]) -> EventLoopFuture<[M]>] = []

    public func getAll(on loop: EventLoop = Loop.current) -> EventLoopFuture<[M]> {
        self.get(["*"], on: loop)
            .flatMapThrowing { try $0.map { try $0.decode(M.self) } }
            .flatMap { self.evaluateEagerLoads(for: $0) }
    }

    public func getFirst(on loop: EventLoop = Loop.current) -> EventLoopFuture<M> {
        self.first(on: loop)
            .flatMapThrowing { try $0.unwrap(or: RuneError(info: "Unable to find first element.")) }
            .flatMapThrowing { try $0.decode(M.self) }
    }

    public func with<R: RelationAllowed>(
        from eagerLoadKeyPath: KeyPath<M, M.HasOne<R>>,
        to: KeyPath<R.Value, R.Value.BelongsTo<M>>,
        on loop: EventLoop = Loop.current,
        db: Database = DB.default
    ) -> ModelQuery<M> {
        self.eagerLoads.append { results in
            // If there are no results, don't need to eager load.
            guard let firstResult = results.first else {
                return loop.future([])
            }

            return firstResult[keyPath: eagerLoadKeyPath]
                .load(results)
                .flatMapThrowing { relationshipResults in
                    var updatedResults = [M]()
                    
                    let dict = Dictionary(grouping: relationshipResults, by: { $0[keyPath: to].id })

                    for (index, result) in results.enumerated() {
                        let values = dict[result.id as! M.Value.Identifier]
                        result[keyPath: eagerLoadKeyPath].wrappedValue = try R.from(values?.first)
                        updatedResults.append(result)
                    }

                    return updatedResults
                }
        }
        
        return self
    }

    /// Evaluate all of the eager loads, sequentially.
    private func evaluateEagerLoads(for models: [M], on loop: EventLoop = Loop.current)
        -> EventLoopFuture<[M]>
    {
        self.eagerLoads
            .reduce(loop.future(models)) { future, eagerLoad in
                future.flatMap { eagerLoad($0) }
            }
    }
}
