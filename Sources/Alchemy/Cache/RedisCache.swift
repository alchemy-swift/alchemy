import Foundation
import RediStack

public final class RedisCache: Cache {
    private let redis: Redis
    
    /// Initialize this cache with a Redis client.
    ///
    /// - Parameter redis: The client to cache with.
    public init(_ redis: Redis = Services.redis) {
        self.redis = redis
    }
    
    public func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        self.redis.get(RedisKey(key), as: String.self).map { $0.map(C.init) ?? nil }
    }
    
    public func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> {
        if let time = time {
            return self.redis.setex(RedisKey(key), to: value.stringValue, expirationInSeconds: time.seconds)
        } else {
            return self.redis.set(RedisKey(key), to: value.stringValue)
        }
    }
    
    public func has(_ key: String) -> EventLoopFuture<Bool> {
        self.redis.exists(RedisKey(key)).map { $0 > 0 }
    }
    
    public func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        self.get(key).flatMap { (value: C?) -> EventLoopFuture<C?> in
            guard let value = value else {
                return .new(nil)
            }
            
            return self.redis.delete(RedisKey(key)).transform(to: value)
        }
    }
    
    public func delete(_ key: String) -> EventLoopFuture<Void> {
        self.redis.delete(RedisKey(key)).voided()
    }
    
    public func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.redis.increment(RedisKey(key), by: amount)
    }
    
    public func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.redis.decrement(RedisKey(key), by: amount)
    }
    
    public func wipe() -> EventLoopFuture<Void> {
        self.redis.command("FLUSHDB").voided()
    }
}
