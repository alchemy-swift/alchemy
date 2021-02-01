import NIO
import RediStack

/// A client for interfacing with a Redis instance.
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
    ///   - socket: The `Socket` to connect to. Can provide multiple
    ///     sockets if using a Redis cluster.
    ///   - password: The password for authenticating connections.
    ///   - database: The database index to connect to. Defaults to
    ///     nil, which uses the default index, 0.
    ///   - poolSize: The connection pool size to use for each
    ///     connection pool. **Note:** There is one connection pool
    ///     per `EventLoop` of your application (meaning 1 per logical
    ///     core on your machine).
    public convenience init(
        _ instances: Socket...,
        password: String? = nil,
        database: Int? = nil,
        poolSize: RedisConnectionPoolSize = .maximumActiveConnections(1)
    ) {
        self.init(
            config: RedisConnectionPool.Configuration(
                initialServerConnectionAddresses: instances.map(\.nio),
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

/// Alchemy specific.
extension Redis {
    /// Wrapper around sending commands to Redis.
    ///
    /// - Parameters:
    ///   - name: The name of the command.
    ///   - args: Any arguments for the command.
    /// - Returns: A future containing the return value of the
    ///   command.
    public func command(_ name: String, args: RESPValueConvertible...) -> EventLoopFuture<RESPValue> {
        self.command(name, args: args)
    }
    
    /// Wrapper around sending commands to Redis.
    ///
    /// - Parameters:
    ///   - name: The name of the command.
    ///   - args: An array of arguments for the command.
    /// - Returns: A future containing the return value of the
    ///   command.
    public func command(_ name: String, args: [RESPValueConvertible]) -> EventLoopFuture<RESPValue> {
        self.send(command: name, with: args.map { $0.convertedToRESPValue() })
    }
    
    /// Evaluate the given Lua script.
    ///
    /// - Parameters:
    ///   - script: The script to run.
    ///   - keys: The arguments that represent Redis keys. See
    ///     [EVAL](https://redis.io/commands/eval) docs for details.
    ///   - args: All other arguments.
    /// - Returns: A future that completes with the result of the
    ///   script.
    public func eval(_ script: String, keys: [String] = [], args: [RESPValueConvertible] = []) -> EventLoopFuture<RESPValue> {
        self.command("EVAL", args: [script] + [keys.count] + keys + args)
    }
    
    /// Subscribe to a single channel.
    ///
    /// - Parameters:
    ///   - channel: The name of the channel to subscribe to.
    ///   - messageReciver: The closure to execute when a message
    ///     comes through the given channel.
    /// - Returns: A future that completes when the subscription is
    ///   established.
    public func subscribe(to channel: RedisChannelName, messageReciver: @escaping (RESPValue) -> Void) -> EventLoopFuture<Void> {
        self.subscribe(to: [channel]) { _, value in messageReciver(value) }
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
