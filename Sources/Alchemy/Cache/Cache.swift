import Foundation

public protocol Cache {
    func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?>
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void>
    func has(_ key: String) -> EventLoopFuture<Bool>
    func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?>
    func delete(_ key: String) -> EventLoopFuture<Void>
    func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int>
    func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int>
    func wipe() -> EventLoopFuture<Void>
}

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

public protocol CacheAllowed {
    init?(_ string: String)
    var stringValue: String { get }
}

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
