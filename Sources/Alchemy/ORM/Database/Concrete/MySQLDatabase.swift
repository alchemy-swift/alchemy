import NIO
import PostgresNIO

// Not working at the moment, seems like https://github.com/vapor/mysql-nio has some larger updates coming
// soon.
public final class MySQLDatabase: Database {
    public init() {}
    
    public func rawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        fatalError()
    }
    
    public func preparedQuery(_ sql: String, values: [DatabaseField], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        fatalError()
    }
    
    public func shutdown() {
        fatalError()
    }
}
