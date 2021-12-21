import NIO
import NIOConcurrencyHelpers
import RediStack

/// A client for interfacing with a Redis instance.
public struct Redis: Service {
    let provider: RedisProvider
    
    public init(provider: RedisProvider) {
        self.provider = provider
    }
    
    /// Shuts down this `Redis` client, closing it's associated
    /// connection pools.
    public func shutdown() throws {
        try provider.shutdown()
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
        return .configuration(
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
    public static func configuration(_ config: RedisConnectionPool.Configuration) -> Redis {
        return Redis(provider: ConnectionPool(config: config))
    }
}

/// Under the hood provider for `Redis`. Used so either connection pools
/// or connections can be injected into `Redis` for accessing redis.
public protocol RedisProvider {
    /// Get a redis client for running commands.
    func getClient() -> RedisClient
    
    /// Shut down.
    func shutdown() throws
    
    /// Runs a transaction on the redis client using a given closure.
    ///
    /// - Parameter transaction: An asynchronous transaction to run on
    ///   the connection.
    /// - Returns: The resulting value of the transaction.
    func transaction<T>(_ transaction: @escaping (RedisProvider) async throws -> T) async throws -> T
}

/// A connection pool is a redis provider with a pool per `EventLoop`.
private final class ConnectionPool: RedisProvider {
    /// Map of `EventLoop` identifiers to respective connection pools.
    private var poolStorage: [ObjectIdentifier: RedisConnectionPool] = [:]
    private var poolLock = Lock()
    
    /// The configuration to create pools with.
    private var config: RedisConnectionPool.Configuration

    init(config: RedisConnectionPool.Configuration) {
        self.config = config
    }

    func getClient() -> RedisClient {
        getPool()
    }

    func transaction<T>(_ transaction: @escaping (RedisProvider) async throws -> T) async throws -> T {
        let pool = getPool()
        return try await pool.leaseConnection { conn in
            pool.eventLoop.asyncSubmit { try await transaction(conn) }
        }.get()
    }

    func shutdown() throws {
        try poolLock.withLock {
            try poolStorage.values.forEach {
                let promise: EventLoopPromise<Void> = $0.eventLoop.makePromise()
                $0.close(promise: promise)
                try promise.futureResult.wait()
            }
        }
    }

    /// Gets or creates a pool for the current `EventLoop`.
    ///
    /// - Returns: A `RedisConnectionPool` associated with the current
    ///   `EventLoop` for sending commands to.
    private func getPool() -> RedisConnectionPool {
        let loop = Loop.current
        let key = ObjectIdentifier(loop)
        return poolLock.withLock {
            if let pool = self.poolStorage[key] {
                return pool
            } else {
                let newPool = RedisConnectionPool(configuration: self.config, boundEventLoop: loop)
                self.poolStorage[key] = newPool
                return newPool
            }
        }
    }
}
