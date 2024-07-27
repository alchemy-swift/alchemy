import AsyncAlgorithms
import ServiceLifecycle

/// Queue lets you run queued jobs to be processed in the background. Jobs are
/// persisted by the given `QueueProvider`.
public final class Queue: IdentifiedService {
    public typealias Identifier = ServiceIdentifier<Queue>

    /// The default channel to dispatch jobs on for all queues.
    public static var defaultChannel = "default"

    /// The number of workers on this queue.
    public var workers: Int

    /// The provider backing this queue.
    private let provider: QueueProvider

    /// Initialize a queue backed by the given provider.
    public init(provider: QueueProvider) {
        self.provider = provider
        self.workers = 0
    }
    
    /// Enqueues a generic `Job` to this queue on the given channel.
    ///
    /// - Parameters:
    ///   - job: A job to enqueue to this queue.
    ///   - channel: The channel on which to enqueue the job. Defaults
    ///     to `Queue.defaultChannel`.
    public func enqueue<J: Job>(_ job: J, channel: String = defaultChannel) async throws {
        Jobs.register(J.self)
        let payload = try job.payload(for: self, channel: channel)
        let data = JobData(payload: payload,
                           jobName: J.name,
                           channel: channel,
                           recoveryStrategy: job.recoveryStrategy,
                           backoff: job.retryBackoff)
        try await provider.enqueue(data)
    }

    /// Dequeue the next job from a given set of channels, ordered by
    /// priority.
    ///
    /// - Parameter channels: The channels to dequeue from.
    /// - Returns: A dequeued `Job`, if there is one.
    func dequeue(from channels: [String]) async throws -> JobData? {
        guard let channel = channels.first else {
            return nil
        }

        guard let job = try await provider.dequeue(from: channel) else {
            return try await dequeue(from: Array(channels.dropFirst()))
        }

        return job
    }

    func complete(_ job: JobData, outcome: JobOutcome) async throws {
        try await provider.complete(job, outcome: outcome)
    }

    public func shutdown() async throws {
        try await provider.shutdown()
    }
}
