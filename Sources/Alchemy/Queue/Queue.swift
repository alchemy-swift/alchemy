import NIO

/// Queue lets you run queued jobs to be processed in the background.
/// Jobs are persisted by the given `QueueProvider`.
public final class Queue: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    /// The default channel to dispatch jobs on for all queues.
    public static let defaultChannel = "default"
    /// The default rate at which workers poll queues.
    public static let defaultPollRate: TimeAmount = .seconds(1)
    
    /// The ids of any workers associated with this queue and running in this
    /// process.
    public var workers: [String] = []

    /// The provider backing this queue.
    let provider: QueueProvider
    
    /// Initialize a queue backed by the given provider.
    ///
    /// - Parameter provider: A queue provider to back this queue with.
    public init(provider: QueueProvider) {
        self.provider = provider
    }
    
    /// Enqueues a generic `Job` to this queue on the given channel.
    ///
    /// - Parameters:
    ///   - job: A job to enqueue to this queue.
    ///   - channel: The channel on which to enqueue the job. Defaults
    ///     to `Queue.defaultChannel`.
    public func enqueue<J: Job>(_ job: J, channel: String = defaultChannel) async throws {
        try await provider.enqueue(JobData(job, channel: channel))
    }

    public func shutdown() async throws {
        try await provider.shutdown()
    }
}

extension Job {
    /// Dispatch this Job on a queue.
    ///
    /// - Parameters:
    ///   - queue: The queue to dispatch on.
    ///   - channel: The name of the channel to dispatch on.
    public func dispatch(on queue: Queue = Q, channel: String = Queue.defaultChannel) async throws {
        try await queue.enqueue(self, channel: channel)
    }
}
