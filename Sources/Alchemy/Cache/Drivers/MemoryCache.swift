import Foundation

/// An in memory driver for `Cache` for testing.
public final class MemoryCache: CacheDriver {
    var data: [String: MemoryCacheItem] = [:]
    
    /// Create this cache populated with the given data.
    ///
    /// - Parameter defaultData: The initial items in the Cache.
    init(_ defaultData: [String: MemoryCacheItem] = [:]) {
        data = defaultData
    }
    
    /// Gets an item and validates that it isn't expired, deleting it
    /// if it is.
    private func getItem(_ key: String) -> MemoryCacheItem? {
        guard let item = self.data[key] else {
            return nil
        }
        
        if !item.isValid {
            self.data[key] = nil
            return nil
        } else {
            return item
        }
    }
    
    // MARK: Cache
    
    public func get<L: LosslessStringConvertible>(_ key: String) throws -> L? {
        try getItem(key)?.cast()
    }
    
    public func set<L: LosslessStringConvertible>(_ key: String, value: L, for time: TimeAmount?) {
        data[key] = MemoryCacheItem(text: value.description, expiration: time.map { Date().adding(time: $0) })
    }
    
    public func has(_ key: String) -> Bool {
        getItem(key) != nil
    }
    
    public func remove<L: LosslessStringConvertible>(_ key: String) throws -> L? {
        let val: L? = try getItem(key)?.cast()
        data.removeValue(forKey: key)
        return val
    }
    
    public func delete(_ key: String) async throws {
        data.removeValue(forKey: key)
    }
    
    public func increment(_ key: String, by amount: Int) throws -> Int {
        if let existing = getItem(key) {
            let currentVal: Int = try existing.cast()
            let newVal = currentVal + amount
            self.data[key]?.text = "\(newVal)"
            return newVal
        } else {
            self.data[key] = .init(text: "\(amount)")
            return amount
        }
    }
    
    public func decrement(_ key: String, by amount: Int) throws -> Int {
        try increment(key, by: -amount)
    }
    
    public func wipe() {
        data = [:]
    }
}

/// An in memory cache item.
public struct MemoryCacheItem {
    fileprivate var text: String
    fileprivate var expiration: Int?
    
    fileprivate var isValid: Bool {
        guard let expiration = self.expiration else {
            return true
        }
        
        return expiration > Int(Date().timeIntervalSince1970)
    }
    
    /// Create a mock cache item.
    ///
    /// - Parameters:
    ///   - text: The text of the item.
    ///   - expiration: An optional expiration time, in seconds since
    ///     epoch.
    public init(text: String, expiration: Int? = nil) {
        self.text = text
        self.expiration = expiration
    }
    
    fileprivate func cast<L: LosslessStringConvertible>() throws -> L {
        try L(text).unwrap(or: CacheError("Unable to cast '\(text)' to \(L.self)"))
    }
}

extension Cache {
    /// Create a cache backed by an in memory dictionary. Useful for
    /// tests.
    ///
    /// - Parameter data: Any data to initialize your cache with.
    ///   Defaults to an empty dict.
    /// - Returns: A memory backed cache.
    public static func memory(_ data: [String: MemoryCacheItem] = [:]) -> Cache {
        Cache(MemoryCache(data))
    }
    
    /// A cache backed by an in memory dictionary. Useful for tests.
    public static var memory: Cache {
        .memory()
    }
    
    /// Fakes a cache using by a memory based cache. Useful for tests.
    ///
    /// - Parameters:
    ///   - id: The identifier of the cache to fake. Defaults to `default`.
    ///   - data: Any data to initialize your cache with. Defaults to
    ///     an empty dict.
    /// - Returns: A `MemoryCache` for verifying test expectations.
    @discardableResult
    public static func fake(_ identifier: Identifier = .default, _ data: [String: MemoryCacheItem] = [:]) -> MemoryCache {
        let driver = MemoryCache(data)
        let cache = Cache(driver)
        register(identifier, cache)
        return driver
    }
}
