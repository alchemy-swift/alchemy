import NIOCore
import RediStack

public final class StubRedis: RedisProvider {
    private var isShutdown = false
    
    var stubs: [String: RESPValue] = [:]
    
    public func stub(_ command: String, response: RESPValue) {
        stubs[command] = response
    }
    
    // MARK: RedisProvider
    
    public func getClient() -> RedisClient {
        self
    }
    
    public func transaction<T>(_ transaction: @escaping (RedisProvider) async throws -> T) async throws -> T {
        try await transaction(self)
    }
    
    public func shutdown() throws {
        isShutdown = true
    }
}

extension StubRedis: RedisClient {
    public var eventLoop: EventLoop { Loop.current }
    
    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        guard !isShutdown else {
            return eventLoop.future(error: RedisError(reason: "This stubbed redis client has been shutdown."))
        }
        
        guard let stub = stubs.removeValue(forKey: command) else {
            return eventLoop.future(error: RedisError(reason: "No stub found for Redis command \(command). Please stub it's response with `stub()`."))
        }
        
        return eventLoop.future(stub)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        eventLoop.future(error: RedisError(reason: "pub/sub stubbing isn't supported, yet"))
    }

    public func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        eventLoop.future(error: RedisError(reason: "pub/sub stubbing isn't supported, yet"))
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        eventLoop.future(error: RedisError(reason: "pub/sub stubbing isn't supported, yet"))
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        eventLoop.future(error: RedisError(reason: "pub/sub stubbing isn't supported, yet"))
    }

    public func logging(to logger: Logger) -> RedisClient {
        self
    }
}
