import NIO

/// Conform to this protocol to implement a custom queue provider.
public protocol QueueProvider {
    /// Enqueue a job.
    func enqueue(_ job: JobData) async throws
    
    /// Dequeue the next job from the given channel.
    func dequeue(from channel: String) async throws -> JobData?
    
    /// Handle an in progress job that has been completed with the
    /// given outcome.
    ///
    /// The `JobData` will have any fields that should be updated
    /// (such as `attempts`) already updated when it is passed
    /// to this function.
    func complete(_ job: JobData, outcome: JobOutcome) async throws
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
