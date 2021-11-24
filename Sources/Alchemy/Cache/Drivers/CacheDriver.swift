import Foundation

public protocol CacheDriver {
    /// Get the value for `key`.
    ///
    /// - Parameter key: The key of the cache record.
    /// - Returns: The value, if it exists.
    func get<L: LosslessStringConvertible>(_ key: String) async throws -> L?
    
    /// Set a record for `key`.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to set.
    /// - Parameter time: How long the cache record should live.
    ///   Defaults to nil, indicating the record has no expiry.
    func set<L: LosslessStringConvertible>(_ key: String, value: L, for time: TimeAmount?) async throws
    
    /// Determine if a record for the given key exists.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: Whether the record exists.
    func has(_ key: String) async throws -> Bool
    
    /// Delete and return a record at `key`.
    ///
    /// - Parameter key: The key to delete.
    /// - Returns: The deleted record, if it existed.
    func remove<L: LosslessStringConvertible>(_ key: String) async throws -> L?
    
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
