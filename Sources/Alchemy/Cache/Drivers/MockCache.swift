import Foundation

/// An in memory driver for `Cache` for testing.
final class MockCacheDriver: CacheDriver {
    private var data: [String: MockCacheItem] = [:]
    
    /// Create this cache populated with the given data.
    ///
    /// - Parameter defaultData: The initial items in the Cache.
    init(_ defaultData: [String: MockCacheItem] = [:]) {
        self.data = defaultData
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
    
    func get<C>(_ key: String) -> EventLoopFuture<C?> where C : CacheAllowed {
        catchError {
            try .new(self.getItem(key)?.cast())
        }
    }
    
    func set<C>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> where C : CacheAllowed {
        .new(self.data[key] = .init(
                text: value.stringValue,
                expiration: time.map { Date().adding(time: $0) })
        )
    }
    
    func has(_ key: String) -> EventLoopFuture<Bool> {
        .new(self.getItem(key) != nil)
    }
    
    func remove<C>(_ key: String) -> EventLoopFuture<C?> where C : CacheAllowed {
        catchError {
            let val: C? = try self.getItem(key)?.cast()
            self.data.removeValue(forKey: key)
            return .new(val)
        }
    }
    
    func delete(_ key: String) -> EventLoopFuture<Void> {
        self.data.removeValue(forKey: key)
        return .new()
    }
    
    func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        catchError {
            if let existing = self.getItem(key) {
                let currentVal: Int = try existing.cast()
                let newVal = currentVal + amount
                self.data[key]?.text = "\(newVal)"
                return .new(newVal)
            } else {
                self.data[key] = .init(text: "\(amount)")
                return .new(amount)
            }
        }
    }
    
    func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.increment(key, by: -amount)
    }
    
    func wipe() -> EventLoopFuture<Void> {
        .new(self.data = [:])
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
