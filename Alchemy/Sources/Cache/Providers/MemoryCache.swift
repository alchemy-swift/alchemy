import Foundation

/// An in memory provider for `Cache` for testing.
public final class MemoryCache: CacheProvider {
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
        
        guard item.isValid else {
            self.data[key] = nil
            return nil
        }
        
        return item
    }
    
    // MARK: Cache
    
    public func get<L: LosslessStringConvertible>(_ key: String) throws -> L? {
        try getItem(key)?.cast()
    }
    
    public func set<L: LosslessStringConvertible>(_ key: String, value: L, for time: Duration?) {
        data[key] = MemoryCacheItem(value: value.description, expiration: time.map { Date().adding(time: $0) })
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
        guard let existing = getItem(key) else {
            self.data[key] = .init(value: "\(amount)")
            return amount
        }
        
        
        let currentVal: Int = try existing.cast()
        let newVal = currentVal + amount
        self.data[key]?.value = "\(newVal)"
        return newVal
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
    fileprivate var value: String
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
    public init(value: String, expiration: Int? = nil) {
        self.value = value
        self.expiration = expiration
    }
    
    fileprivate func cast<L: LosslessStringConvertible>() throws -> L {
        guard let converted = L(value) else {
            throw CacheError("Unable to cast '\(value)' to \(L.self)")
        }

        return converted
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
        Cache(provider: MemoryCache(data))
    }
    
    /// A cache backed by an in memory dictionary. Useful for tests.
    public static var memory: Cache {
        .memory()
    }
    
    /// Fakes a cache using by a memory based cache. Useful for tests.
    ///
    /// - Parameters:
    ///   - key: The identifier of the cache to fake. Defaults to nil.
    ///   - data: Any data to initialize your cache with. Defaults to
    ///     an empty dict.
    /// - Returns: A `MemoryCache` for verifying test expectations.
    @discardableResult
    public static func fake(_ key: ReferenceWritableKeyPath<Container, Cache>? = nil, _ data: [String: MemoryCacheItem] = [:]) -> MemoryCache {
        let provider = MemoryCache(data)
        let cache = Cache(provider: provider)
        if let key {
            Container.main[keyPath: key] = cache
        } else {
            Container.main.set(cache)
        }

        return provider
    }
}
