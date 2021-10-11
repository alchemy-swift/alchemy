import Foundation

/// An in memory driver for `Cache` for testing.
final class MockCacheDriver: CacheDriver {
    var data: [String: MockCacheItem] = [:]
    
    /// Create this cache populated with the given data.
    ///
    /// - Parameter defaultData: The initial items in the Cache.
    init(_ defaultData: [String: MockCacheItem] = [:]) {
        data = defaultData
    }
    
    /// Gets an item and validates that it isn't expired, deleting it
    /// if it is.
    private func getItem(_ key: String) -> MockCacheItem? {
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
    
    func get<C: CacheAllowed>(_ key: String) throws -> C? {
        try getItem(key)?.cast()
    }
    
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) {
        data[key] = MockCacheItem(text: value.stringValue, expiration: time.map { Date().adding(time: $0) })
    }
    
    func has(_ key: String) -> Bool {
        getItem(key) != nil
    }
    
    func remove<C: CacheAllowed>(_ key: String) throws -> C? {
        let val: C? = try getItem(key)?.cast()
        data.removeValue(forKey: key)
        return val
    }
    
    func delete(_ key: String) async throws {
        data.removeValue(forKey: key)
    }
    
    func increment(_ key: String, by amount: Int) throws -> Int {
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
    
    func decrement(_ key: String, by amount: Int) throws -> Int {
        try increment(key, by: -amount)
    }
    
    func wipe() {
        data = [:]
    }
}

/// An in memory cache item.
public struct MockCacheItem {
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
    
    fileprivate func cast<C: CacheAllowed>() throws -> C {
        try C(self.text).unwrap(or: CacheError("Unable to cast '\(self.text)' to \(C.self)"))
    }
}

extension Cache {
    /// Create a cache backed by an in memory dictionary. Useful for
    /// tests.
    ///
    /// - Parameter data: Optional mock data to initialize your cache
    ///   with. Defaults to an empty dict.
    /// - Returns: A mock cache.
    public static func mock(_ data: [String: MockCacheItem] = [:]) -> Cache {
        Cache(MockCacheDriver(data))
    }
}
