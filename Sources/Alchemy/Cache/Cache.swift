import Foundation

/// A type for accessing a persistant cache. Supported drivers are
/// `RedisCache`, `DatabaseCache` and, for testing, `MockCache`.
public final class Cache: Service {
    private let driver: CacheDriver
    
    public init(_ driver: CacheDriver) {
        self.driver = driver
    }
    
    /// Get the value for `key`.
    ///
    /// - Parameter key: The key of the cache record.
    /// - Returns: A future containing the value, if it exists.
    public func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        driver.get(key)
    }
    
    /// Set a record for `key`.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to set.
    /// - Parameter time: How long the cache record should live.
    ///   Defaults to nil, indicating the record has no expiry.
    /// - Returns: A future indicating the record has been set.
    public func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount? = nil) -> EventLoopFuture<Void> {
        driver.set(key, value: value, for: time)
    }
    
    /// Determine if a record for the given key exists.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: A future indicating if the record exists.
    public func has(_ key: String) -> EventLoopFuture<Bool> {
        driver.has(key)
    }
    
    /// Delete and return a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    /// - Returns: A future with the deleted record, if it existed.
    public func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        driver.remove(key)
    }
    
    /// Delete a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    /// - Returns: A future that completes when the record is deleted.
    public func delete(_ key: String) -> EventLoopFuture<Void> {
        driver.delete(key)
    }
    
    /// Increment the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to increment.
    ///   - amount: The amount to increment by. Defaults to 1.
    /// - Returns: A future containing the new value of the record.
    public func increment(_ key: String, by amount: Int = 1) -> EventLoopFuture<Int> {
        driver.increment(key, by: amount)
    }
    
    /// Decrement the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to decrement.
    ///   - amount: The amount to decrement by. Defaults to 1.
    /// - Returns: A future containing the new value of the record.
    public func decrement(_ key: String, by amount: Int = 1) -> EventLoopFuture<Int> {
        driver.decrement(key, by: amount)
    }
    
    /// Clear the entire cache.
    ///
    /// - Returns: A future that completes when the cache has been
    ///   wiped.
    public func wipe() -> EventLoopFuture<Void> {
        driver.wipe()
    }
}
