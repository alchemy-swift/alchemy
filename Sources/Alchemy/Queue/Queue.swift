import NIO

public final class Queue: Service {
    public static let defaultChannel = "default"
    public static let defaultPollRate: TimeAmount = .seconds(1)
    
    private let driver: QueueDriver
    
    public init(_ driver: QueueDriver) {
        self.driver = driver
    }
    
    /// Enqueues a generic `Job` to this queue on the given channel.
    public func enqueue<J: Job>(_ job: J, channel: String = defaultChannel) -> EventLoopFuture<Void> {
        // If the Job hasn't been registered, register it.
        if !JobDecoding.isRegistered(J.self) {
            JobDecoding.register(J.self)
        }
        return catchError { driver.enqueue(try JobData(job, channel: channel)) }
    }
    
    public func startWorker(
        for channels: [String] = [Queue.defaultChannel],
        pollRate: TimeAmount = Queue.defaultPollRate,
        on eventLoop: EventLoop = Loop.group.next()
    ) {
        driver.startWorker(for: channels, pollRate: pollRate, on: eventLoop)
    }
}

extension Job {
    /// Dispatch this Job on a queue.
    ///
    /// - Parameters:
    ///   - queue: The queue to dispatch on.
    ///   - channel: The name of the channel to dispatch on.
    /// - Returns: A future that completes when this job has been
    ///  dispatched to the queue.
    public func dispatch(on queue: Queue = .default, channel: String = Queue.defaultChannel) -> EventLoopFuture<Void> {
        queue.enqueue(self)
    }
}
