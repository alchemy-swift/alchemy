import Foundation
import NIO

public protocol Queue {
    associatedtype QueueItem: PersistedJob

    var eventLoop: EventLoop { get set }
    @discardableResult
    func enqueue<T: Job>(_ type: T.Type, _ payload: T.Payload) -> EventLoopFuture<Void>
    func dequeue() -> EventLoopFuture<QueueItem?>
    func complete(_ item: QueueItem, success: Bool) -> EventLoopFuture<Void>
    func requeue(_ item: QueueItem) -> EventLoopFuture<Void>
}
