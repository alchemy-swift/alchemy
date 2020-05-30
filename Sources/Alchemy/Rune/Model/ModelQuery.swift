import Foundation
import NIO

public class ModelQuery<E: Model>: Query {
    public func getAll(on loop: EventLoop = Loop.current) -> EventLoopFuture<[E]> {
        self.get(columns, on: loop)
            .flatMapThrowing { try $0.map { try $0.decode(E.self) } }
    }

    public func getFirst(on loop: EventLoop = Loop.current) -> EventLoopFuture<E> {
        self.first(on: loop)
            .flatMapThrowing { try $0.unwrap(or: RuneError(info: "Unable to find first element.")) }
            .flatMapThrowing { try $0.decode(E.self) }
    }
}
