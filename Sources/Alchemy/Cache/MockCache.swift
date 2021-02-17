import Foundation

public final class MockCache: Cache {
    private struct Item {
        var text: String
        var expiration: Int?
        
        var isValid: Bool {
            guard let expiration = self.expiration else {
                return true
            }
            
            return expiration > Int(Date().timeIntervalSince1970)
        }
        
        func cast<C: CacheAllowed>() -> C? {
            self.isValid ? C(self.text) : nil
        }
    }
    
    private var data: [String: Item] = [:]
    
    public func get<C>(_ key: String) -> EventLoopFuture<C?> where C : CacheAllowed {
        .new(self.data[key]?.cast())
    }
    
    public func set<C>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> where C : CacheAllowed {
        .new(self.data[key] = .init(
                text: value.stringValue,
                expiration: time.map { Date().adding(time: $0) })
        )
    }
    
    public func has(_ key: String) -> EventLoopFuture<Bool> {
        .new(self.data[key]?.isValid ?? false)
    }
    
    public func remove<C>(_ key: String) -> EventLoopFuture<C?> where C : CacheAllowed {
        .new(self.data[key]?.cast())
    }
    
    public func delete(_ key: String) -> EventLoopFuture<Void> {
        self.data.removeValue(forKey: key)
        return .new()
    }
    
    public func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        catchError {
            if let existing = self.data[key] {
                let currentVal: Int = try existing.cast().unwrap(or: CacheError("Couldn't convert cache item to Int."))
                let newVal = currentVal + amount
                self.data[key] = .init(text: "\(newVal)", expiration: existing.expiration)
                return .new(newVal)
            } else {
                self.data[key] = .init(text: "\(amount)")
                return .new(amount)
            }
        }
    }
    
    public func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.increment(key, by: amount)
    }
    
    public func wipe() -> EventLoopFuture<Void> {
        .new(self.data = [:])
    }
}
