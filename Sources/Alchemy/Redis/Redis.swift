import NIO
import RediStack

/// A client for interfacing with a Redis instance.
public struct Redis: Service {
    let driver: RedisDriver
    
    public init(driver: RedisDriver) {
        self.driver = driver
    }
    
    /// Shuts down this `Redis` client, closing it's associated
    /// connection pools.
    public func shutdown() throws {
        try driver.shutdown()
    }
    
    /// A single redis connection
    public static func connection(
        _ host: String,
        port: Int = 6379,
        password: String? = nil,
        database: Int? = nil,
        poolSize: RedisConnectionPoolSize = .maximumActiveConnections(1)
    ) -> Redis {
        return .cluster(.ip(host: host, port: port), password: password, database: database, poolSize: poolSize)
    }
    
    /// Convenience initializer for creating a redis client with the
    /// given information.
    ///
    /// - Parameters:
    ///   - socket: The `Socket` to connect to. Can provide multiple
    ///     sockets if using a Redis cluster.
    ///   - password: The password for authenticating connections.
    ///   - database: The database index to connect to. Defaults to
    ///     nil, which uses the default index, 0.
    ///   - poolSize: The connection pool size to use for each
    ///     connection pool. **Note:** There is one connection pool
    ///     per `EventLoop` of your application (meaning 1 per logical
    ///     core on your machine).
    public static func cluster(
        _ sockets: Socket...,
        password: String? = nil,
        database: Int? = nil,
        poolSize: RedisConnectionPoolSize = .maximumActiveConnections(1)
    ) -> Redis {
        return .rawPoolConfiguration(
            RedisConnectionPool.Configuration(
                initialServerConnectionAddresses: sockets.map {
                    do {
                        switch $0 {
                        case let .ip(host, port):
                            return try .makeAddressResolvingHost(host, port: port)
                        case let .unix(path):
                            return try .init(unixDomainSocketPath: path)
                        }
                    } catch {
                        fatalError("Error generating socket address from `Socket` \(self)!")
                    }
                },
                maximumConnectionCount: poolSize,
                connectionFactoryConfiguration: RedisConnectionPool.ConnectionFactoryConfiguration(
                    connectionInitialDatabase: database,
                    connectionPassword: password,
                    connectionDefaultLogger: Log.logger
                )
            )
        )
    }
    
    /// Creates a Redis client that will connect with the given pool
    /// configuration.
    ///
    /// - Parameters:
    ///   - config: The configuration of the pool backing this `Redis`
    ///     client.
    public static func rawPoolConfiguration(_ config: RedisConnectionPool.Configuration) -> Redis {
        return Redis(driver: ConnectionPool(config: config))
    }
}

/// Under the hood driver for `Redis`. Used so either connection pools
/// or connections can be injected into `Redis` for accessing redis.
public protocol RedisDriver {
    /// Get a redis client for running commands.
    func getClient() -> RedisClient
    
    /// Shut down.
    func shutdown() throws
    
    /// Runs a transaction on the redis client using a given closure.
    ///
    /// - Parameter transaction: An asynchronous transaction to run on
    ///   the connection.
    /// - Returns: The resulting value of the transaction.
    func transaction<T>(_ transaction: @escaping (RedisDriver) async throws -> T) async throws -> T
}

/// A connection pool is a redis driver with a pool per `EventLoop`.
private final class ConnectionPool: RedisDriver {
    /// Map of `EventLoop` identifiers to respective connection pools.
    @Locked private var poolStorage: [ObjectIdentifier: RedisConnectionPool] = [:]
    
    /// The configuration to create pools with.
    private var config: RedisConnectionPool.Configuration

    init(config: RedisConnectionPool.Configuration) {
        self.config = config
    }

    func getClient() -> RedisClient {
        getPool()
    }

    func transaction<T>(_ transaction: @escaping (RedisDriver) async throws -> T) async throws -> T {
        let pool = getPool()
        return try await pool.leaseConnection { conn in
            pool.eventLoop.wrapAsync { try await transaction(conn) }
        }.get()
    }

    func shutdown() throws {
        try poolStorage.values.forEach {
            let promise: EventLoopPromise<Void> = $0.eventLoop.makePromise()
            $0.close(promise: promise)
            try promise.futureResult.wait()
        }
    }

    /// Gets or creates a pool for the current `EventLoop`.
    ///
    /// - Returns: A `RedisConnectionPool` associated with the current
    ///   `EventLoop` for sending commands to.
    private func getPool() -> RedisConnectionPool {
        let loop = Loop.current
        let key = ObjectIdentifier(loop)
        if let pool = self.poolStorage[key] {
            return pool
        } else {
            let newPool = RedisConnectionPool(configuration: self.config, boundEventLoop: loop)
            self.poolStorage[key] = newPool
            return newPool
        }
    }
}
