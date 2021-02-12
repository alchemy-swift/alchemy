import Foundation

protocol CacheAllowed {
    init?(_ string: String)
    var stringValue: String { get }
}

extension Bool: CacheAllowed {
    var stringValue: String { "\(self)" }
}

extension String: CacheAllowed {
    var stringValue: String { self }
}

extension Int: CacheAllowed {
    var stringValue: String { "\(self)" }
}

extension Double: CacheAllowed {
    var stringValue: String { "\(self)" }
}

protocol Cache {
    func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?>
    func put<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount) -> EventLoopFuture<Void>
    func has(_ key: String) -> EventLoopFuture<Bool>
    func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?>
    func forget(_ key: String) -> EventLoopFuture<Void>
    func increment(_ key: String, by: Int) -> EventLoopFuture<Int>
    func decrement(_ key: String, by: Int) -> EventLoopFuture<Int>
    func wipe() -> EventLoopFuture<Void>
}
