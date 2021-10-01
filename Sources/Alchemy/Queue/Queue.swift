import NIO

/// Queue lets you run queued jobs to be processed in the background.
/// Jobs are persisted by the given `QueueDriver`.
public final class Queue: Service {
    /// The default channel to dispatch jobs on for all queues.
    public static let defaultChannel = "default"
    /// The default rate at which workers poll queues.
    public static let defaultPollRate: TimeAmount = .seconds(1)
    
    /// The driver backing this queue.
    private let driver: QueueDriver
    
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
        // If the Job hasn't been registered, register it.
        if !JobDecoding.isRegistered(J.self) {
            JobDecoding.register(J.self)
        }
        
        return try await driver.enqueue(JobData(job, channel: channel))
    }
    
    /// Start a worker that dequeues and runs jobs from this queue.
    ///
    /// - Parameters:
    ///   - channels: The channels this worker should monitor for
    ///     work. Defaults to `Queue.defaultChannel`.
    ///   - pollRate: The rate at which this worker should poll the
    ///     queue for new work. Defaults to `Queue.defaultPollRate`.
    ///   - eventLoop: The loop this worker will run on. Defaults to
    ///     your apps next available loop.
    public func startWorker(
        for channels: [String] = [Queue.defaultChannel],
        pollRate: TimeAmount = Queue.defaultPollRate,
        on eventLoop: EventLoop = Loop.group.next()
    ) {
        let loopId = ObjectIdentifier(eventLoop).debugDescription.dropLast().suffix(6)
        Log.info("[Queue] starting worker \(loopId)")
        driver.startWorker(for: channels, pollRate: pollRate, on: eventLoop)
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
