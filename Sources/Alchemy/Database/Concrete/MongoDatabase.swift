import NIO
import PostgresNIO

/// Example of adding a custom db.
public final class MongoDatabase: Database {

    public let grammar = Grammar()

    public func rawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        fatalError()
    }
    
    public func query(_ sql: String, values: [DatabaseValue], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        fatalError()
    }
    
    public func shutdown() {
        fatalError()
    }
}
