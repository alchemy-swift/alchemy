import Foundation
import NIO

// Database
// Redis
protocol Cache {
    func get(key: String) -> EventLoopFuture<String?>
    func pull(key: String) -> EventLoopFuture<Void>
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void>
    func has(key: String) -> EventLoopFuture<Bool>
    func increment(key: String) -> EventLoopFuture<Int>
    func decrement(key: String) -> EventLoopFuture<Int>
    func forget(key: String) -> EventLoopFuture<Bool>
    func wipe() -> EventLoopFuture<Void>
}

// Caching requests?
