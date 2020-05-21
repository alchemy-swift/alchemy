import NIO
import PostgresNIO

// Not working at the moment, seems like https://github.com/vapor/mysql-nio has some larger updates coming
// soon.
public final class MySQLDatabase: Database {

    public let grammar = Grammar()

    public init() {}
    
    public func rawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        fatalError()
    }
    
    public func query(_ sql: String, values: [DatabaseValue], on loop: EventLoop)
        -> EventLoopFuture<[DatabaseRow]>
    {
        fatalError()
    }
    
    public func shutdown() {
        fatalError()
    }
}
