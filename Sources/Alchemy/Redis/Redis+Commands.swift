import Foundation
import RediStack

/// RedisClient conformance. See `RedisClient` for docs.
extension Redis: RedisClient {
    
    // MARK: RedisClient
    
    public var eventLoop: EventLoop {
        Loop.current
    }
    
    public func logging(to logger: Logger) -> RedisClient {
        driver.getClient().logging(to: logger)
    }
    
    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        driver.getClient()
            .send(command: command, with: arguments).hop(to: Loop.current)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        driver.getClient()
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
        driver.getClient()
            .psubscribe(
                to: patterns,
                messageReceiver: receiver,
                onSubscribe: subscribeHandler,
                onUnsubscribe: unsubscribeHandler
            )
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        driver.getClient().unsubscribe(from: channels)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        driver.getClient().punsubscribe(from: patterns)
    }

    // MARK: - Alchemy sugar

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
    
    /// Sends a Redis transaction over a single connection. Wrapper around
    /// "MULTI" ... "EXEC".
    public func transaction<T>(_ action: @escaping (Redis) -> EventLoopFuture<T>) -> EventLoopFuture<RESPValue> {
        driver.leaseConnection { conn in
            return conn.send(command: "MULTI")
                .flatMap { _ in action(Redis(driver: conn)) }
                .flatMap { _ in return conn.send(command: "EXEC") }
        }
    }
}

extension RedisConnection: RedisDriver {
    func getClient() -> RedisClient {
        self
    }
    
    func shutdown() throws {
        try close().wait()
    }
    
    func leaseConnection<T>(_ transaction: @escaping (RedisConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        transaction(self)
    }
}
