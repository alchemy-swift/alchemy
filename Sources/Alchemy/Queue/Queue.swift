import NIO

/// Queue lets you run queued jobs to be processed in the background.
/// Jobs are persisted by the given `QueueDriver`.
public final class Queue: Service {
    /// The default channel to dispatch jobs on for all queues.
    public static let defaultChannel = "default"
    /// The default rate at which workers poll queues.
    public static let defaultPollRate: TimeAmount = .seconds(1)
    
    /// The driver backing this queue.
    let driver: QueueDriver
    
    /// Initialize a queue backed by the given driver.
    ///
    /// - Parameter driver: A queue driver to back this queue with.
    public init(_ driver: QueueDriver) {
        self.driver = driver
    }
    
    /// Enqueues a generic `Job` to this queue on the given channel.
    ///
    /// - Parameters:
    ///   - job: A job to enqueue to this queue.
    ///   - channel: The channel on which to enqueue the job. Defaults
    ///     to `Queue.defaultChannel`.
    public func enqueue<J: Job>(_ job: J, channel: String = defaultChannel) async throws {
        try await driver.enqueue(JobData(job, channel: channel))
    }
}

extension Job {
    /// Dispatch this Job on a queue.
    ///
    /// - Parameters:
    ///   - queue: The queue to dispatch on.
    ///   - channel: The name of the channel to dispatch on.
    public func dispatch(on queue: Queue = .default, channel: String = Queue.defaultChannel) async throws {
        try await queue.enqueue(self, channel: channel)
    }
}
