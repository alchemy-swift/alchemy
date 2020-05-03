import PostgresKit

public final class Database {
    private var pooler = ConnectionPooler()
    private var loop: EventLoop!
    var grammar: Grammar = Grammar()
    
    public init() {}
    
    public func test(loop: EventLoop) -> EventLoopFuture<String> {
        self.loop = loop
        return self.query(rawSQL: "SELECT version()")
            .map { "\($0)" }
    }
}

// Some examples
// nio async http: https://github.com/swift-server/async-http-client/pull/31/files
// vapor: https://github.com/vapor/async-kit/tree/master/Sources/AsyncKit/ConnectionPool
//        & https://github.com/vapor/postgres-kit/blob/master/Sources/PostgresKit/ConnectionPool%2BPostgres.swift
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
    func query() -> Query {
        return Query(database: self)
    }

    func query(rawSQL: String) -> EventLoopFuture<[PostgresRow]> {
        return self.pooler.get(on: loop)
            .flatMap { $0.simpleQuery(rawSQL) }
    }

    func run(query: Query) -> EventLoopFuture<[PostgresRow]> {
        self.query(rawSQL: "")
    }
}
