import PostgresNIO

public final class Database {
    private var pooler = ConnectionPooler()
    private var loop: EventLoop!
    
    public init() {}
    
    public func test(loop: EventLoop) -> EventLoopFuture<String> {
        self.loop = loop
        return self.query(rawSQL: "SELECT version()")
            .map { "\($0)" }
    }
}

final class ConnectionPooler {
    // Never close for now.
    private var connection: PostgresConnection?
    private var currentLookup: EventLoopFuture<PostgresConnection>?
    
    func get(on loop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        if let connection = self.connection {
            print("reusing")
            return loop.makeSucceededFuture(connection)
        } else {
            let address = try! SocketAddress(ipAddress: "127.0.0.1", port: 5432)
            let newConnection = PostgresConnection
                .connect(to: address, on: loop)
                .flatMap { conn -> EventLoopFuture<PostgresConnection> in
                    print("Authing")
                    return conn.authenticate(username: "josh", database: "roam", password: "password")
                        .map { conn }
                }
                .always { result in
                    switch result {
                    case .success(let conn):
                        print("Connected to postgres")
                        self.connection = conn
                        print("Yay")
                    case .failure(let error):
                        print("Error connecting to postgres: \(error)")
                    }
                }
            self.currentLookup = newConnection
            return newConnection
        }
    }
}

extension Database: Injectable {
    public static func create(_ isMock: Bool) -> Database {
        struct Shared {
            static let stored = Database()
        }
        
        return Shared.stored
    }
}

/// Queries.
public extension Database {
    func query(rawSQL: String) -> EventLoopFuture<[PostgresRow]> {
        return self.pooler.get(on: loop)
            .flatMap { $0.simpleQuery(rawSQL) }
    }
    
    func query(sql: Query) -> EventLoopFuture<[PostgresRow]> {
        self.query(rawSQL: sql.toString())
    }
}

public struct Query {
    func toString() -> String {
        "SELECT version()"
    }
}

/// Migrations
public extension Database {
    func add(table: Table) {

    }

    func migrate(table: Table, migration: () -> Void) {

    }
}
