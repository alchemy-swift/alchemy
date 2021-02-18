import Foundation

/// An in memory driver for `Cache` for testing.
public final class MockCache: Cache {
    /// An in memory cache item.
    public struct Item {
        var text: String
        var expiration: Int?
        
        var isValid: Bool {
            guard let expiration = self.expiration else {
                return true
            }
            
            return expiration > Int(Date().timeIntervalSince1970)
        }
        
        public init(text: String, expiration: Int? = nil) {
            self.text = text
            self.expiration = expiration
        }
        
        func cast<C: CacheAllowed>() throws -> C {
            try C(self.text).unwrap(or: CacheError("Unable to cast '\(self.text)' to \(C.self)"))
        }
    }
    
    private var data: [String: Item] = [:]
    
    /// Create this cache populated with the given data.
    ///
    /// - Parameter defaultData: The initial items in the Cache.
    public init(_ defaultData: [String: Item] = [:]) {
        self.data = defaultData
    }
    
    /// Gets an item and validates that it isn't expired, deleting it
    /// if it is.
    private func getItem(_ key: String) -> Item? {
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
    
    public func get<C>(_ key: String) -> EventLoopFuture<C?> where C : CacheAllowed {
        catchError {
            try .new(self.getItem(key)?.cast())
        }
    }
    
    public func set<C>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> where C : CacheAllowed {
        .new(self.data[key] = .init(
                text: value.stringValue,
                expiration: time.map { Date().adding(time: $0) })
        )
    }
    
    public func has(_ key: String) -> EventLoopFuture<Bool> {
        .new(self.getItem(key) != nil)
    }
    
    public func remove<C>(_ key: String) -> EventLoopFuture<C?> where C : CacheAllowed {
        catchError {
            let val: C? = try self.getItem(key)?.cast()
            self.data.removeValue(forKey: key)
            return .new(val)
        }
    }
    
    public func delete(_ key: String) -> EventLoopFuture<Void> {
        self.data.removeValue(forKey: key)
        return .new()
    }
    
    public func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
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
    
    public func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.increment(key, by: -amount)
    }
    
    public func wipe() -> EventLoopFuture<Void> {
        .new(self.data = [:])
    }
}
