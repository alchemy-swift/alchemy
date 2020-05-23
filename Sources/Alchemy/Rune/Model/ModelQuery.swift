import Foundation
import NIO

public class ModelQuery<E: Model>: Query {

    public func get(_ columns: [Column]? = nil, on loop: EventLoop = Loop.current) -> EventLoopFuture<[E]> {
        return self.get(columns, on: loop)
            .flatMapThrowing { try $0.map { try $0.decode(E.self) } }
    }
}
