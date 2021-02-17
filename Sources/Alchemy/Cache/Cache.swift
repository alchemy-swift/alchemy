import Foundation

/// A type for accessing a persistant cache. Currently drivers are
/// `RedisCache`, `DatabaseCache` and, for testing, `MockCache`.
public protocol Cache {
    /// Get the value for `key`.
    ///
    /// - Parameter key: The key of the cache record.
    /// - Returns: A future containing the value, if it exists.
    func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?>
    
    /// Set a record for `key`.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to set.
    /// - Parameter time: How long the cache record should live.
    ///   Defaults to nil, indicating the record has no expiry.
    /// - Returns: A future indicating the record has been set.
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void>
    
    /// Determine if a record for the given key exists.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: A future indicating if the record exists.
    func has(_ key: String) -> EventLoopFuture<Bool>
    
    /// Delete and return a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    /// - Returns: A future with the deleted record, if it existed.
    func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?>
    
    /// Delete a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    /// - Returns: A future that completes when the record is deleted.
    func delete(_ key: String) -> EventLoopFuture<Void>
    
    /// Increment the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to increment.
    ///   - amount: The amount to increment by. Defaults to 1.
    /// - Returns: A future containing the new value of the record.
    func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int>
    
    /// Decrement the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to decrement.
    ///   - amount: The amount to decrement by. Defaults to 1.
    /// - Returns: A future containing the new value of the record.
    func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int>
    /// Clear the entire cache.
    ///
    /// - Returns: A future that completes when the cache has been
    ///   wiped.
    func wipe() -> EventLoopFuture<Void>
}

// Convenient defaults.
extension Cache {
    public func increment(_ key: String, by amount: Int = 1) -> EventLoopFuture<Int> {
        self.increment(key, by: amount)
    }
    
    public func decrement(_ key: String, by amount: Int = 1) -> EventLoopFuture<Int> {
        self.decrement(key, by: amount)
    }
    
    public func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount? = nil) -> EventLoopFuture<Void> {
        self.set(key, value: value, for: time)
    }
}

/// A type that can be set in a Cache. Must be convertible to and from
/// a `String`.
public protocol CacheAllowed {
    /// Initialize this type with a string.
    ///
    /// - Parameter string: The string representing this object.
    init?(_ string: String)
    
    /// The string value of this instance.
    var stringValue: String { get }
}

// MARK: - default CacheAllowed conformances

extension Bool: CacheAllowed {
    public var stringValue: String { "\(self)" }
}

extension String: CacheAllowed {
    public var stringValue: String { self }
}

extension Int: CacheAllowed {
    public var stringValue: String { "\(self)" }
}

extension Double: CacheAllowed {
    public var stringValue: String { "\(self)" }
}
