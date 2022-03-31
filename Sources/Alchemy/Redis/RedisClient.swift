import NIO
import NIOConcurrencyHelpers
import NIOSSL
import RediStack

/// A client for interfacing with a Redis instance.
public struct RedisClient: Service, RediStack.RedisClient {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    let provider: RedisProvider
    
    public init(provider: RedisProvider) {
        self.provider = provider
    }
    
    /// Shuts down this client, closing it's associated connection pools.
    public func shutdown() throws {
        try provider.shutdown()
    }
    
    // MARK: RediStack.RedisClient
    
    public var eventLoop: EventLoop {
        Loop.current
    }
    
    public func logging(to logger: Logger) -> RediStack.RedisClient {
        provider.logging(to: logger)
    }
    
    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        wrapError {
            try provider.getClient()
                .send(command: command, with: arguments).hop(to: Loop.current)
        }
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        wrapError {
            try provider.getClient()
                .subscribe(
                    to: channels,
                    messageReceiver: receiver,
                    onSubscribe: subscribeHandler,
                    onUnsubscribe: unsubscribeHandler
                )
        }
    }

    public func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        wrapError {
            try provider.getClient()
                .psubscribe(
                    to: patterns,
                    messageReceiver: receiver,
                    onSubscribe: subscribeHandler,
                    onUnsubscribe: unsubscribeHandler
                )
        }
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        wrapError { try provider.getClient().unsubscribe(from: channels) }
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        wrapError { try provider.getClient().punsubscribe(from: patterns) }
    }
    
    // MARK: Creating
    
    /// A single redis connection
    public static func connection(
        _ host: String,
        port: Int = 6379,
        password: String? = nil,
        database: Int? = nil,
        poolSize: RedisConnectionPoolSize = .maximumActiveConnections(1),
        tlsConfiguration: TLSConfiguration? = nil
    ) -> RedisClient {
        return .cluster(.ip(host: host, port: port), password: password, database: database, poolSize: poolSize, tlsConfiguration: tlsConfiguration)
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
        poolSize: RedisConnectionPoolSize = .maximumActiveConnections(1),
        tlsConfiguration: TLSConfiguration? = nil
    ) -> RedisClient {
        return .configuration(
            RedisConnectionPool.Configuration(
                initialServerConnectionAddresses: [],
                maximumConnectionCount: poolSize,
                connectionFactoryConfiguration: RedisConnectionPool.ConnectionFactoryConfiguration(
                    connectionInitialDatabase: database,
                    connectionPassword: password,
                    connectionDefaultLogger: Log.logger,
                    tlsConfiguration: tlsConfiguration
                )
            ),
            addresses: sockets
        )
    }
    
    /// Creates a Redis client that will connect with the given pool
    /// configuration.
    ///
    /// - Parameters:
    ///   - config: The configuration of the pool backing this `Redis`
    ///     client.
    public static func configuration(_ config: RedisConnectionPool.Configuration) -> RedisClient {
        return RedisClient(provider: ConnectionPool(config: config))
    }
    
    fileprivate static func configuration(_ config: RedisConnectionPool.Configuration, addresses: [Socket]) -> RedisClient {
        return RedisClient(provider: ConnectionPool(config: config, lazyAddresses: addresses))
    }
}

/// A connection pool is a redis provider with a pool per `EventLoop`.
private final class ConnectionPool: RedisProvider, RediStack.RedisClient {
    /// Map of `EventLoop` identifiers to respective connection pools.
    private var poolStorage: [ObjectIdentifier: RedisConnectionPool] = [:]
    private var poolLock = Lock()
    private var lazyAddresses: [Socket]?
    private var logger: Logger?
    
    /// The configuration to create pools with.
    private var config: RedisConnectionPool.Configuration

    init(config: RedisConnectionPool.Configuration, lazyAddresses: [Socket]? = nil) {
        self.config = config
        self.lazyAddresses = lazyAddresses
    }
    
    // MARK: - RedisProvider

    func getClient() throws -> RediStack.RedisClient {
        try getPool()
    }

    func transaction<T>(_ transaction: @escaping (RedisProvider) async throws -> T) async throws -> T {
        let pool = try getPool()
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
    private func getPool() throws -> RedisConnectionPool {
        let loop = Loop.current
        let key = ObjectIdentifier(loop)
        return try poolLock.withLock {
            if let pool = self.poolStorage[key] {
                return pool
            } else {
                var config = self.config
                if let lazyAddresses = lazyAddresses {
                    let initialAddresses: [SocketAddress] = try lazyAddresses.map {
                        switch $0 {
                        case let .ip(host, port):
                            return try .makeAddressResolvingHost(host, port: port)
                        case let .unix(path):
                            return try .init(unixDomainSocketPath: path)
                        }
                    }
                    
                    config = RedisConnectionPool.Configuration(
                        initialServerConnectionAddresses: initialAddresses,
                        maximumConnectionCount: config.maximumConnectionCount,
                        connectionFactoryConfiguration: config.factoryConfiguration,
                        minimumConnectionCount: config.minimumConnectionCount,
                        connectionBackoffFactor: config.connectionRetryConfiguration.backoff.factor,
                        initialConnectionBackoffDelay: config.connectionRetryConfiguration.backoff.initialDelay,
                        connectionRetryTimeout: config.connectionRetryConfiguration.timeout,
                        poolDefaultLogger: config.poolDefaultLogger)
                }
                
                let newPool = RedisConnectionPool(configuration: config, boundEventLoop: loop)
                self.poolStorage[key] = newPool
                if let logger = logger {
                    return newPool.logging(to: logger) as? RedisConnectionPool ?? newPool
                } else {
                    return newPool
                }
            }
        }
    }
    
    // MARK: RediStack.RedisClient
    
    var eventLoop: EventLoop { Loop.current }
    
    func logging(to logger: Logger) -> RediStack.RedisClient {
        self.logger = logger
        return self
    }
    
    func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        wrapError { try getClient().punsubscribe(from: patterns) }
    }
    
    func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        wrapError { try getClient().unsubscribe(from: channels) }
    }
    
    func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        wrapError { try getClient().send(command: command, with: arguments) }
    }
    
    private func wrapError<T>(_ closure: () throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        do { return try closure() }
        catch { return Loop.current.makeFailedFuture(error) }
    }
}

extension RedisConnection: RedisProvider {
    public func getClient() -> RediStack.RedisClient {
        self
    }
    
    public func shutdown() throws {
        try close().wait()
    }
    
    public func transaction<T>(_ transaction: @escaping (RedisProvider) async throws -> T) async throws -> T {
        try await transaction(self)
    }
}

private func wrapError<T>(_ closure: () throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
    do { return try closure() }
    catch { return Loop.current.makeFailedFuture(error) }
}
