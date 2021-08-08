import NIO

public protocol QueueDriver {
    /// Add a job to the end of the Queue.
    func enqueue(_ job: JobData) -> EventLoopFuture<Void>
    /// Dequeue the next job from the given channel.
    func dequeue(from channel: String) -> EventLoopFuture<JobData?>
    /// Handle an in progress job that has been completed with the
    /// given outcome.
    ///
    /// The `JobData` will have any fields that should be updated
    /// (such as `attempts`) already updated when it is passed
    /// to this function.
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

extension QueueDriver {
    /// Dequeue the next job from a given set of channels, ordered by
    /// priority.
    ///
    /// - Parameter channels: The channels to dequeue from.
    /// - Returns: A future containing a dequeued `Job`, if there is
    ///   one.
    func dequeue(from channels: [String]) -> EventLoopFuture<JobData?> {
        guard let channel = channels.first else {
            return .new(nil)
        }
        
        return dequeue(from: channel)
            .flatMap { result in
                guard let result = result else {
                    return dequeue(from: Array(channels.dropFirst()))
                }
                
                return .new(result)
            }
    }
    
    /// Start monitoring a queue for jobs to run.
    func startWorker(for channels: [String], pollRate: TimeAmount, on eventLoop: EventLoop) {
        return eventLoop.execute {
            self.runNext(from: channels)
                .whenComplete { _ in
                    // Run check again in the `pollRate`.
                    eventLoop.scheduleTask(in: pollRate) {
                        self.startWorker(for: channels, pollRate: pollRate, on: eventLoop)
                    }
                }
        }
    }

    private func runNext(from channels: [String]) -> EventLoopFuture<Void> {
        dequeue(from: channels)
            .flatMapErrorThrowing {
                Log.error("[Queue] error dequeueing job from `\(channels)`. \($0)")
                throw $0
            }
            .flatMap { jobData in
                guard let jobData = jobData else {
                    return .new()
                }
                
                Log.debug("Dequeued job \(jobData.jobName) from queue \(jobData.channel)")
                return self.execute(jobData)
                    .flatMap { self.runNext(from: channels) }
            }
    }

    private func execute(_ jobData: JobData) -> EventLoopFuture<Void> {
        var jobData = jobData
        return catchError {
            do {
                let job = try JobDecoding.decode(jobData)
                return job.run()
                    .always {
                        job.finished(result: $0)
                        do {
                            jobData.json = try job.jsonString()
                        } catch {
                            Log.error("[QueueWorker] tried updating Job persistance object after completion, but encountered error \(error)")
                        }
                    }
            } catch {
                Log.error("error decoding job named \(jobData.jobName). Error was: \(error).")
                throw error
            }
        }
        .flatMapAlways { (result: Result<Void, Error>) -> EventLoopFuture<Void> in
            jobData.attempts += 1
            switch result {
            case .success:
                return self.complete(jobData, outcome: .success)
            case .failure where jobData.canRetry:
                jobData.backoffUntil = jobData.nextRetryDate()
                return self.complete(jobData, outcome: .retry)
            case .failure:
                return self.complete(jobData, outcome: .failed)
            }
        }
    }
}
