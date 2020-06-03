import Foundation
import NIO

public class ModelQuery<M: Model>: Query {
    private var eagerLoads: [([M]) -> EventLoopFuture<[M]>] = []

    public func getAll(on loop: EventLoop = Loop.current) -> EventLoopFuture<[M]> {
        self.get(["\(M.tableName).*"], on: loop)
            .flatMapThrowing { try $0.map { try $0.decode(M.self) } }
            .flatMap { self.evaluateEagerLoads(for: $0) }
    }

    public func getFirst(on loop: EventLoop = Loop.current) -> EventLoopFuture<M> {
        self.first(["\(M.tableName).*"], on: loop)
            .flatMapThrowing { try $0.unwrap(or: RuneError(info: "Unable to find first element.")) }
            .flatMapThrowing { try $0.decode(M.self) }
            .flatMap { self.evaluateEagerLoads(for: [$0]) }
            .flatMapThrowing { try $0.first.unwrap(or: RuneError(info: "Unable to find first element.")) }
    }

    public func with<R: Relationship>(
        _ relationshipKeyPath: KeyPath<M, R>,
        on loop: EventLoop = Loop.current,
        db: Database = DB.default
    ) -> ModelQuery<M> where R.From == M {
        self.eagerLoads.append { results in
            // If there are no results, don't need to eager load.
            guard let firstResult = results.first else {
                return loop.future([])
            }

            return firstResult[keyPath: relationshipKeyPath]
                .load(results, from: relationshipKeyPath)
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
