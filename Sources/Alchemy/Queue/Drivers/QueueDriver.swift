import NIO

/// Conform to this protocol to implement a custom driver for the
/// `Queue` class.
public protocol QueueDriver {
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

extension QueueDriver {
    /// Dequeue the next job from a given set of channels, ordered by
    /// priority.
    ///
    /// - Parameter channels: The channels to dequeue from.
    /// - Returns: A dequeued `Job`, if there is one.
    func dequeue(from channels: [String]) async throws -> JobData? {
        guard let channel = channels.first else {
            return nil
        }
        
        if let job = try await dequeue(from: channel) {
            return job
        } else {
            return try await dequeue(from: Array(channels.dropFirst()))
        }
    }
    
    /// Start monitoring a queue for jobs to run.
    ///
    /// - Parameters:
    ///   - channels: The channels this worker should monitor.
    ///   - pollRate: The rate at which the worker should check the
    ///     queue for work.
    ///   - eventLoop: The loop on which this worker should run.
    func startWorker(for channels: [String], pollRate: TimeAmount, on eventLoop: EventLoop) {
        eventLoop.wrapAsync { try await runNext(from: channels) }
            .whenComplete { _ in
                // Run check again in the `pollRate`.
                eventLoop.scheduleTask(in: pollRate) {
                    self.startWorker(for: channels, pollRate: pollRate, on: eventLoop)
                }
            }
    }

    private func runNext(from channels: [String]) async throws -> Void {
        do {
            guard let jobData = try await dequeue(from: channels) else {
                return
            }
            
            Log.debug("[Queue] dequeued job \(jobData.jobName) from queue \(jobData.channel)")
            try await execute(jobData)
            try await runNext(from: channels)
        } catch {
            Log.error("[Queue] error dequeueing job from `\(channels)`. \(error)")
            throw error
        }
    }
    
    private func execute(_ jobData: JobData) async throws -> Void {
        var jobData = jobData
        jobData.attempts += 1
        
        func retry(ignoreAttempt: Bool = false) async throws {
            if ignoreAttempt { jobData.attempts -= 1 }
            jobData.backoffUntil = jobData.nextRetryDate()
            try await complete(jobData, outcome: .retry)
        }
        
        var job: Job?
        do {
            job = try JobDecoding.decode(jobData)
            try await job?.run()
            job?.finished(result: .success(()))
            try await complete(jobData, outcome: .success)
        } catch where jobData.canRetry {
            try await retry()
        } catch where (error as? JobError) == JobError.unknownType {
            // So that an old worker won't fail new jobs.
            try await retry(ignoreAttempt: true)
        } catch {
            job?.finished(result: .failure(error))
            try await complete(jobData, outcome: .failed)
        }
    }
}
