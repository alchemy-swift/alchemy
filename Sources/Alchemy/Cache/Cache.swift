import Foundation

/// A type for accessing a persistant cache. Supported drivers are
/// `RedisCache`, `DatabaseCache` and, for testing, `MockCache`.
public final class Cache: Service {
    private let driver: CacheDriver
    
    /// Initializer this cache with a driver. Prefer static functions
    /// like `.database()` or `.redis()` when configuring your
    /// application's cache.
    ///
    /// - Parameter driver: A driver to back this cache with.
    public init(_ driver: CacheDriver) {
        self.driver = driver
    }
    
    /// Get the value for `key`.
    ///
    /// - Parameters:
    ///   - key: The key of the cache record.
    ///   - type: The type to coerce fetched key to for return.
    /// - Returns: The value for the key, if it exists.
    public func get<L: LosslessStringConvertible>(_ key: String, as type: L.Type = L.self) async throws -> L? {
        try await driver.get(key)
    }
    
    /// Set a record for `key`.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to set.
    /// - Parameter time: How long the cache record should live.
    ///   Defaults to nil, indicating the record has no expiry.
    public func set<L: LosslessStringConvertible>(_ key: String, value: L, for time: TimeAmount? = nil) async throws {
        try await driver.set(key, value: value, for: time)
    }
    
    /// Determine if a record for the given key exists.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: Whether the record exists.
    public func has(_ key: String) async throws -> Bool {
        try await driver.has(key)
    }
    
    /// Delete and return a record at `key`.
    ///
    /// - Parameters:
    ///   - key: The key to delete.
    ///   - type: The type to coerce the removed key to for return.
    /// - Returns: The deleted record, if it existed.
    public func remove<L: LosslessStringConvertible>(_ key: String, as type: L.Type = L.self) async throws -> L? {
        try await driver.remove(key)
    }
    
    /// Delete a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    public func delete(_ key: String) async throws {
        try await driver.delete(key)
    }
    
    /// Increment the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to increment.
    ///   - amount: The amount to increment by. Defaults to 1.
    /// - Returns: The new value of the record.
    public func increment(_ key: String, by amount: Int = 1) async throws -> Int {
        try await driver.increment(key, by: amount)
    }
    
    /// Decrement the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to decrement.
    ///   - amount: The amount to decrement by. Defaults to 1.
    /// - Returns: The new value of the record.
    public func decrement(_ key: String, by amount: Int = 1) async throws -> Int {
        try await driver.decrement(key, by: amount)
    }
    
    /// Clear the entire cache.
    public func wipe() async throws {
        try await driver.wipe()
    }
}
