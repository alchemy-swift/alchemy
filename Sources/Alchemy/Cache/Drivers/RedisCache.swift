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
    
    func get<C: CacheAllowed>(_ key: String) async throws -> C? {
        guard let value = try await redis.get(RedisKey(key), as: String.self).get() else {
            return nil
        }
        
        return try C(value).unwrap(or: CacheError("Unable to cast cache item `\(key)` to \(C.self)."))
    }
    
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) async throws {
        if let time = time {
            try await redis.setex(RedisKey(key), to: value.stringValue, expirationInSeconds: time.seconds).get()
        } else {
            try await redis.set(RedisKey(key), to: value.stringValue).get()
        }
    }
    
    func has(_ key: String) async throws -> Bool {
        try await redis.exists(RedisKey(key)).get() > 0
    }
    
    func remove<C: CacheAllowed>(_ key: String) async throws -> C? {
        guard let value: C = try await get(key) else {
            return nil
        }
        
        _ = try await redis.delete(RedisKey(key)).get()
        return value
    }
    
    func delete(_ key: String) async throws {
        _ = try await redis.delete(RedisKey(key)).get()
    }
    
    func increment(_ key: String, by amount: Int) async throws -> Int {
        try await redis.increment(RedisKey(key), by: amount).get()
    }
    
    func decrement(_ key: String, by amount: Int) async throws -> Int {
        try await redis.decrement(RedisKey(key), by: amount).get()
    }
    
    func wipe() async throws {
        _ = try await redis.command("FLUSHDB")
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
