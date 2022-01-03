import NIO
import RediStack

/// RedisClient conformance. See `RedisClient` for docs.
extension RedisClient: RediStack.RedisClient {
    
    // MARK: RediStack.RedisClient
    
    public var eventLoop: EventLoop {
        Loop.current
    }
    
    public func logging(to logger: Logger) -> RediStack.RedisClient {
        provider.getClient().logging(to: logger)
    }
    
    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        provider.getClient()
            .send(command: command, with: arguments).hop(to: Loop.current)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        provider.getClient()
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
        provider.getClient()
            .psubscribe(
                to: patterns,
                messageReceiver: receiver,
                onSubscribe: subscribeHandler,
                onUnsubscribe: unsubscribeHandler
            )
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        provider.getClient().unsubscribe(from: channels)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        provider.getClient().punsubscribe(from: patterns)
    }

    // MARK: - Alchemy sugar

    /// Wrapper around sending commands to Redis.
    ///
    /// - Parameters:
    ///   - name: The name of the command.
    ///   - args: Any arguments for the command.
    /// - Returns: The return value of the command.
    public func command(_ name: String, args: RESPValueConvertible...) async throws -> RESPValue {
        try await command(name, args: args)
    }
    
    /// Wrapper around sending commands to Redis.
    ///
    /// - Parameters:
    ///   - name: The name of the command.
    ///   - args: An array of arguments for the command.
    /// - Returns: The return value of the command.
    public func command(_ name: String, args: [RESPValueConvertible]) async throws -> RESPValue {
        try await send(command: name, with: args.map { $0.convertedToRESPValue() }).get()
    }
    
    /// Evaluate the given Lua script.
    ///
    /// - Parameters:
    ///   - script: The script to run.
    ///   - keys: The arguments that represent Redis keys. See
    ///     [EVAL](https://redis.io/commands/eval) docs for details.
    ///   - args: All other arguments.
    /// - Returns: The result of the script.
    public func eval(_ script: String, keys: [String] = [], args: [RESPValueConvertible] = []) async throws -> RESPValue {
        try await command("EVAL", args: [script] + [keys.count] + keys + args)
    }
    
    /// Subscribe to a single channel.
    ///
    /// - Parameters:
    ///   - channel: The name of the channel to subscribe to.
    ///   - messageReciver: The closure to execute when a message
    ///     comes through the given channel.
    public func subscribe(to channel: RedisChannelName, messageReciver: @escaping (RESPValue) -> Void) async throws {
        try await subscribe(to: [channel]) { _, value in messageReciver(value) }.get()
    }
    
    /// Sends a Redis transaction over a single connection. Wrapper around
    /// "MULTI" ... "EXEC".
    ///
    /// - Returns: The result of finishing the transaction.
    public func transaction(_ action: @escaping (RedisClient) async throws -> Void) async throws -> RESPValue {
        try await provider.transaction { conn in
            _ = try await conn.getClient().send(command: "MULTI").get()
            try await action(RedisClient(provider: conn))
            return try await conn.getClient().send(command: "EXEC").get()
        }
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
