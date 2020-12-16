import Foundation
import PostgresKit

public protocol Database {
    var grammar: Grammar { get }
    var migrations: [Migration] { get set }
    func query() -> Query
    func runRawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]>
    /// TODO, don't bind NULL since at least postgres seems to complain. Still works tho.
    func runQuery(_ sql: String, values: [DatabaseValue], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]>
    func shutdown()
}

extension Database {
    public func query() -> Query {
        return Query(database: self)
    }
}
