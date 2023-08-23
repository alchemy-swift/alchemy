import Foundation
import RediStack

/// A Redis based provider for `Cache`.
final class RedisCache: CacheProvider {
    private let redis: RedisClient
    
    /// Initialize this cache with a Redis client.
    ///
    /// - Parameter redis: The client to cache with.
    init(_ redis: RedisClient = Redis) {
        self.redis = redis
    }
    
    // MARK: Cache
    
    func get<L: LosslessStringConvertible>(_ key: String) async throws -> L? {
        guard let string = try await redis.get(RedisKey(key), as: String.self).get() else {
            return nil
        }

        guard let value = L(string) else {
            throw CacheError("Unable to cast cache item `\(key)` to \(L.self).")
        }

        return value
    }
    
    func set<L: LosslessStringConvertible>(_ key: String, value: L, for time: TimeAmount?) async throws {
        if let time = time {
            _ = try await redis.transaction { conn in
                try await conn.set(RedisKey(key), to: value.description).get()
                _ = try await conn.send(command: "EXPIRE", with: [.init(from: key), .init(from: time.seconds)]).get()
            }
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
    public static func redis(_ redis: RedisClient = Redis) -> Cache {
        Cache(provider: RedisCache(redis))
    }
    
    /// A cache backed by the default Redis instance.
    public static var redis: Cache {
        .redis()
    }
}
