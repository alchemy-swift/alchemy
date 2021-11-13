import Foundation
import RediStack

/// A Redis based driver for `Cache`.
final class RedisCache: CacheDriver {
    private let redis: Redis
    
    /// Initialize this cache with a Redis client.
    ///
    /// - Parameter redis: The client to cache with.
    init(_ redis: Redis = .default) {
        self.redis = redis
    }
    
    // MARK: Cache
    
    func get<L: LosslessStringConvertible>(_ key: String) async throws -> L? {
        guard let value = try await redis.get(RedisKey(key), as: String.self).get() else {
            return nil
        }
        
        return try L(value).unwrap(or: CacheError("Unable to cast cache item `\(key)` to \(L.self)."))
    }
    
    func set<L: LosslessStringConvertible>(_ key: String, value: L, for time: TimeAmount?) async throws {
        if let time = time {
            try await redis.setex(RedisKey(key), to: value.description, expirationInSeconds: time.seconds).get()
        } else {
            try await redis.set(RedisKey(key), to: value.description).get()
        }
    }
    
    func has(_ key: String) async throws -> Bool {
        try await redis.exists(RedisKey(key)).get() > 0
    }
    
    func remove<L: LosslessStringConvertible>(_ key: String) async throws -> L? {
        guard let value: L = try await get(key) else {
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

extension Cache {
    /// Create a cache backed by Redis.
    ///
    /// - Parameter redis: The redis instance to drive your cache
    ///   with. Defaults to your default `Redis` configuration.
    /// - Returns: A cache.
    public static func redis(_ redis: Redis = Redis.default) -> Cache {
        Cache(RedisCache(redis))
    }
    
    /// A cache backed by the default Redis instance.
    public static var redis: Cache {
        .redis(.default)
    }
}
