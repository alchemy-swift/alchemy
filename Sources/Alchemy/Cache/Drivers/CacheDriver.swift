import Foundation

public protocol CacheDriver {
    /// Get the value for `key`.
    ///
    /// - Parameter key: The key of the cache record.
    /// - Returns: The value, if it exists.
    func get<C: CacheAllowed>(_ key: String) async throws -> C?
    
    /// Set a record for `key`.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to set.
    /// - Parameter time: How long the cache record should live.
    ///   Defaults to nil, indicating the record has no expiry.
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) async throws
    
    /// Determine if a record for the given key exists.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: Whether the record exists.
    func has(_ key: String) async throws -> Bool
    
    /// Delete and return a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    /// - Returns: The deleted record, if it existed.
    func remove<C: CacheAllowed>(_ key: String) async throws -> C?
    
    /// Delete a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    func delete(_ key: String) async throws
    
    /// Increment the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to increment.
    ///   - amount: The amount to increment by. Defaults to 1.
    /// - Returns: The new value of the record.
    func increment(_ key: String, by amount: Int) async throws -> Int
    
    /// Decrement the record at `key` by the give `amount`.
    ///
    /// - Parameters:
    ///   - key: The key to decrement.
    ///   - amount: The amount to decrement by. Defaults to 1.
    /// - Returns: The new value of the record.
    func decrement(_ key: String, by amount: Int) async throws -> Int
    /// Clear the entire cache.
    func wipe() async throws
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
