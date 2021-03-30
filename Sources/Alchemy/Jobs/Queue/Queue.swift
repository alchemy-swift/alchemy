import Foundation
import NIO

public let kDefaultQueueName = "default"

public protocol Queue {
    /// Add a job to the end of the Queue.
    func enqueue(_ job: JobData) -> EventLoopFuture<Void>
    /// Dequeue the next job.
    func dequeue(from queueName: String) -> EventLoopFuture<JobData?>
    /// Handle an in progress job that has been completed with the
    /// given outcome.
    func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void>
}

/// An outcome of when a job is run. It should either be flagged as
/// successful, failed, or be retried.
public enum JobOutcome {
    /// The job succeeded.
    case success
    /// The job failed.
    case failed
    /// The job should be requeued.
    case retry
}

// Default arguments
extension Queue {
    public func dequeue(from queueName: String = kDefaultQueueName) -> EventLoopFuture<JobData?> {
        self.dequeue(from: queueName)
    }
}

extension Job {
    /// Dispatch this Job on a queue.
    ///
    /// - Parameters:
    ///   - queue: The queue to dispatch on.
    ///   - queueName: The name of the queue to dispatch on.
    /// - Returns: A future that completes when this job has been
    ///  dispatched to the queue.
    public func dispatch(on queue: Queue = Services.queue, queueName: String = kDefaultQueueName) -> EventLoopFuture<Void> {
        catchError { queue.enqueue(try JobData(self, queueName: queueName)) }
    }
}
