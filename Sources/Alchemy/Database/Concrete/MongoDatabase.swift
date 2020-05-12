import NIO
import PostgresNIO

/// Example of adding a custom db.
public final class MongoDatabase: Database {
    public func rawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        fatalError()
    }
    
    public func preparedQuery(_ sql: String, values: [DatabaseField.Value], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        fatalError()
    }
    
    public func shutdown() {
        fatalError()
    }
}
