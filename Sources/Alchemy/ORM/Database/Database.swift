import PostgresKit

// Vapor's `PostgresKit` has `EventLoopGroupConnectionPool` with a generic param. When we do our own we won't
// have that. For now leaving as `EventLoopGroupConnectionPool<PostgresConnectionSource>`
public typealias ConnectionPool = EventLoopGroupConnectionPool<PostgresConnectionSource>

public enum PostgreSQL { }
public enum MySQL { }

public final class MySQLDatabase: Database {
    public typealias Kind = MySQL
    public var pool: ConnectionPool?
}

extension MySQLDatabase: Injectable {
    public static func create(identifier: String?, _ isMock: Bool) -> MySQLDatabase {
        struct Storage {
            static let singleton = MySQLDatabase()
        }
        
        return Storage.singleton
    }
}

public final class PostgresDatabase: Database {
    public typealias Kind = PostgreSQL
    public var pool: ConnectionPool?
}

extension PostgresDatabase: Injectable {
    public static func create(identifier: String?, _ isMock: Bool) -> PostgresDatabase {
        struct Storage {
            static var singleton: PostgresDatabase?
            static var dict: [String: PostgresDatabase] = [:]
        }
        
        if let identifier = identifier, let database = Storage.dict[identifier] {
            return database
        } else if let identifier = identifier {
            let newDB = PostgresDatabase()
            Storage.dict[identifier] = newDB
            return newDB
        } else if let singleton = Storage.singleton {
            print("Using singleton.")
            return singleton
        } else {
            print("Creating singleton.")
            let singleton = PostgresDatabase()
            Storage.singleton = singleton
            return singleton
        }
    }
}

public struct DatabaseConfig {
    public enum Socket {
        case ipAddress(host: String, port: Int)
        case unixSocket(path: String)
    }
    
    public let socket: Socket
    public let database: String
    public let username: String
    public let password: String
    
    public init(
        socket: Socket,
        database: String,
        username: String,
        password: String
    ) {
        self.socket = socket
        self.database = database
        self.username = username
        self.password = password
    }
}

public protocol Database: class {
    associatedtype Kind
    
    var pool: ConnectionPool? { get set }
}

extension Database {
    var isConfigured: Bool { self.pool != nil }
    
    public func configure(with config: DatabaseConfig, eventLoopGroup: EventLoopGroup) {
        print("Configuring.")
        //  Initialize the pool.
        let postgresConfig: PostgresConfiguration
        switch config.socket {
        case .ipAddress(let host, let port):
            postgresConfig = .init(
                hostname: host,
                port: port,
                username: config.username,
                password: config.password,
                database: config.database
            )
        case .unixSocket(let name):
            postgresConfig = .init(
                unixDomainSocketPath: name,
                username: config.username,
                password: config.password,
                database: config.database
            )
        }
        
        let pool = EventLoopGroupConnectionPool(
            source: PostgresConnectionSource(configuration: postgresConfig),
            on: eventLoopGroup
        )
        
        self.pool = pool
    }
    
    public func shutdown() {
        self.pool?.shutdown()
    }
    
    public func test() -> EventLoopFuture<String> {
        return self.query("SELECT version()")
            .map { "\($0)" }
    }
}

extension Database {
    func query(_ sql: String) -> EventLoopFuture<[PostgresRow]> {
        guard let pool = pool, self.isConfigured else {
            fatalError("this database hasn't been configured yet. Please call `configure` before running any queries.")
        }
        
        print("Running query '\(sql)'")
        return pool.database(logger: .init(label: "why_is_a_logger_needed"))
            .simpleQuery(sql)
    }
}

/// Example of custom DB

public enum MongoDB { }

public final class MongoDatabase: Database {
    public typealias Kind = MongoDB
    public var pool: ConnectionPool?
    
    // Can optionally override any function such as setup, query, etc.
}

// Then user can write a custom query builder for a `MongoDB` database.

protocol QueryBuilder {
    associatedtype Kind
    func toString() -> String
}

struct MongoBuilder: QueryBuilder {
    // Assuming QueryBuilder has associated type `Kind`
    public typealias Kind = MongoDB
    
    func toString() -> String {
        "db.somecollection.find( {} )"
    }
}


