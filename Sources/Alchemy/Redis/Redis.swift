import NIO
import RediStack

struct Redis {
    /// MARK: - Command
    
    func send(_ command: String, args: [RESPValueConvertible]) -> EventLoopFuture<RESPValue> {
        fatalError()
    }
    
    /// MARK: - Pub/Sub
    
    func publish(to channel: RedisChannelName) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func subscribe(
        _ channels: [RedisChannelName],
        _ callback: (RedisChannelName, RESPValue) -> Void
    ) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    /// Pub/Sub - Pattern Matching
    
    func psubscribe(
        _ patterns: [RedisChannelName],
        _ callback: (RedisChannelName, RESPValue) -> Void
    ) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func punsubscribe(from patterns: [RedisChannelName]) -> EventLoopFuture<Void> {
        fatalError()
    }
}
