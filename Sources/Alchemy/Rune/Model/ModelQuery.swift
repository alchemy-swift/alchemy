import Foundation
import NIO

public class ModelQuery<M: Model>: Query {
    public typealias NestedEagerLoads<R: Model> = (ModelQuery<R>) -> ModelQuery<R>
    
    /// Right now these only run when the query is finished with `getAll` or `getFirst`. If the user finishes
    /// with a `get()` we don't know if/when the decode will happen and how to handle it. Potential ways of
    /// doing it (call eager load @ the `.decode` level of a `DatabaseRow`, but too complicated for now).
    private var eagerLoads: [([M]) -> EventLoopFuture<[M]>] = []

    public func getAll(on loop: EventLoop = Loop.current) -> EventLoopFuture<[M]> {
        self.get(["\(M.tableName).*"], on: loop)
            .flatMapThrowing { try $0.map { try $0.decode(M.self) } }
            .flatMap { self.evaluateEagerLoads(for: $0) }
    }

    public func getFirst(on loop: EventLoop = Loop.current) -> EventLoopFuture<M?> {
        self.first(["\(M.tableName).*"], on: loop)
            .flatMapThrowing { try $0?.decode(M.self) }
            .flatMap { result -> EventLoopFuture<M?> in
                if let result = result {
                    return self.evaluateEagerLoads(for: [result]).map { $0.first }
                } else {
                    return loop.future(nil)
                }
            }
    }
    
    public func unwrapFirst(on loop: EventLoop = Loop.current, or error: Error? = nil) -> EventLoopFuture<M> {
        self.getFirst(on: loop)
            .flatMapThrowing { try $0.unwrap(or: error ?? RuneError(info: "Unable to find first element.")) }
    }

    public func with<R: Relationship>(
        _ relationshipKeyPath: KeyPath<M, R>,
        on loop: EventLoop = Loop.current,
        db: Database = DB.default,
        nested: @escaping NestedEagerLoads<R.To.Value> = { $0 }
    ) -> ModelQuery<M> where R.From == M {
        self.eagerLoads.append { results in
            // If there are no results, don't need to eager load.
            guard let firstResult = results.first else {
                return loop.future([])
            }

            return firstResult[keyPath: relationshipKeyPath]
                .load(
                    results,
                    with: nested,
                    from: relationshipKeyPath
                )
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
