import Foundation
import RediStack

/// A Redis based driver for `Cache`.
final class RedisCacheDriver: CacheDriver {
    private let redis: Redis
    
    /// Initialize this cache with a Redis client.
    ///
    /// - Parameter redis: The client to cache with.
    init(_ redis: Redis = .default) {
        self.redis = redis
    }
    
    // MARK: Cache
    
    func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        self.redis.get(RedisKey(key), as: String.self).map { $0.map(C.init) ?? nil }
    }
    
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> {
        if let time = time {
            return self.redis.setex(RedisKey(key), to: value.stringValue, expirationInSeconds: time.seconds)
        } else {
            return self.redis.set(RedisKey(key), to: value.stringValue)
        }
    }
    
    func has(_ key: String) -> EventLoopFuture<Bool> {
        self.redis.exists(RedisKey(key)).map { $0 > 0 }
    }
    
    func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        self.get(key).flatMap { (value: C?) -> EventLoopFuture<C?> in
            guard let value = value else {
                return .new(nil)
            }
            
            return self.redis.delete(RedisKey(key)).transform(to: value)
        }
    }
    
    func delete(_ key: String) -> EventLoopFuture<Void> {
        self.redis.delete(RedisKey(key)).voided()
    }
    
    func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.redis.increment(RedisKey(key), by: amount)
    }
    
    func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.redis.decrement(RedisKey(key), by: amount)
    }
    
    func wipe() -> EventLoopFuture<Void> {
        self.redis.command("FLUSHDB").voided()
    }
}

public extension Cache {
    /// Create a cache backed by Redis.
    ///
    /// - Parameter redis: The redis instance to drive your cache
    ///   with. Defaults to your default `Redis` configuration.
    /// - Returns: A cache.
    static func redis(_ redis: Redis = Redis.default) -> Cache {
        Cache(RedisCacheDriver(redis))
    }
}
