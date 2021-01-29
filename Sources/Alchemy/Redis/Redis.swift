import NIO
import RediStack

/// Used for interfacing with Redis.
public final class Redis {
    /// Map of `EventLoop` identifiers to respective connection pools.
    @Locked
    private var poolStorage: [ObjectIdentifier: RedisConnectionPool] = [:]
    
    /// The configuration to create pools with.
    private var config: RedisConnectionPool.Configuration
    
    /// Creates a Redis client that will connect with the given
    /// configuration.
    ///
    /// - Parameters:
    ///   - config: The configuration of the pool backing this `Redis`
    ///     client.
    public init(config: RedisConnectionPool.Configuration) {
        self.config = config
    }
    
    /// Convenience initializer for creating a redis client with the
    /// given information.
    ///
    /// - Parameters:
    ///   - socket: The `Socket` to connect to.
    ///   - password: The password for authenticating connections.
    ///   - database: The database index to connect to. Defaults to
    ///     nil, which uses the default index, 0.
    ///   - poolSize: The connection pool size to use for each
    ///     connection pool. **Note:** There is one connection pool
    ///     per `EventLoop` of your application (meaning 1 per logical
    ///     core on your machine).
    public convenience init(
        socket: Socket,
        password: String? = nil,
        database: Int? = nil,
        poolSize: RedisConnectionPoolSize = .maximumActiveConnections(1)
    ) {
        self.init(
            config: RedisConnectionPool.Configuration(
                initialServerConnectionAddresses: [socket.nio],
                maximumConnectionCount: poolSize,
                connectionFactoryConfiguration: RedisConnectionPool.ConnectionFactoryConfiguration(
                    connectionInitialDatabase: database,
                    connectionPassword: password,
                    connectionDefaultLogger: Log.logger
                )
            )
        )
    }
    
    /// Shuts down this `Redis` client, closing it's associated
    /// connection pools.
    public func shutdown() {
        self.poolStorage.values.forEach { $0.close() }
    }
    
    /// Gets or creates a pool for the current `EventLoop`.
    ///
    /// - Returns: A `RedisConnectionPool` associated with the current
    ///   `EventLoop` for sending commands to.
    fileprivate func getPool() -> RedisConnectionPool {
        let loop = Services.eventLoop
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

/// RedisClient conformance. See `RedisClient` for docs.
extension Redis: RedisClient {
    public var eventLoop: EventLoop {
        Services.eventLoop
    }
    
    public func logging(to logger: Logger) -> RedisClient {
        self.getPool().logging(to: logger)
    }
    
    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.getPool().send(command: command, with: arguments).hop(to: Services.eventLoop)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.getPool()
            .subscribe(
                to: channels,
                messageReceiver: receiver,
                onSubscribe: subscribeHandler,
                onUnsubscribe: unsubscribeHandler
            )
    }

    public func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.getPool()
            .psubscribe(
                to: patterns,
                messageReceiver: receiver,
                onSubscribe: subscribeHandler,
                onUnsubscribe: unsubscribeHandler
            )
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        self.getPool().unsubscribe(from: channels)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        self.getPool().punsubscribe(from: patterns)
    }
}
