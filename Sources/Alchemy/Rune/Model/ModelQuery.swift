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

    func with<R: RelationAllowed>(
        _ eagerLoadKeyPath: WritableKeyPath<M, M.HasOne<R>>,
        on loop: EventLoop = Loop.current,
        db: Database
    ){
        self.eagerLoads.append { results in
            // If there are no results, don't need to eager load.
            guard let firstResult = results.first else {
                return loop.future([])
            }

            let theIDs = results.map { $0[keyPath: eagerLoadKeyPath] }

            return firstResult[keyPath: eagerLoadKeyPath]
                .load(results)
                .map { relationshipResults in
                    var updatedResults = [M]()

                    for (index, var result) in results.enumerated() {
                        result[keyPath: eagerLoadKeyPath] = relationshipResults[index]
                        updatedResults.append(result)
                    }

                    return updatedResults
                }
        }
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
