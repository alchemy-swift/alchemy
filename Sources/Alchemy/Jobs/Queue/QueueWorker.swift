import Foundation
import Dispatch
import NIO

/// Monitors a Queue for jobs to dequeue and run.
public final class QueueWorker {
    private let queue: Queue
    private let pollRate: TimeAmount
    private let eventLoop: EventLoop
    
    /// Initialize with a given queue.
    /// - Parameters:
    ///   - queue: The queue to monitor. Defaults to `Services.queue`.
    ///   - pollRate: The time to wait before checking the queue for
    ///     jobs after dequeuing the last job. Defaults to 1 second.
    ///   - eventLoop: The `EventLoop` to dequeue and run jobs on.
    public init(queue: Queue = Services.queue, pollRate: TimeAmount = .seconds(1), eventLoop: EventLoop = Services.eventLoop) {
        self.queue = queue
        self.pollRate = pollRate
        self.eventLoop = eventLoop
    }
    
    /// Start monitoring the queue for jobs to run.
    public func start() {
        self.eventLoop.execute {
            self.runNext()
                .whenComplete { _ in
                    // Run check again in the `pollRate`.
                    self.eventLoop.scheduleTask(in: self.pollRate, self.start)
                }
        }
    }

    private func runNext() -> EventLoopFuture<Void> {
        self.queue
            .dequeue()
            .flatMap { $0.map(self.execute) ?? .new() }
    }

    private func execute(_ jobData: JobData) -> EventLoopFuture<Void> {
        do {
            let job = try JobDecoding.decode(jobData)
            return job.run()
                .flatMapAlways { result in
                    var jobData = jobData
                    jobData.attempts += 1
                    switch result {
                    case .success:
                        return self.queue.complete(jobData, outcome: .success)
                            .map { job.finished(result: result) }
                    case .failure where jobData.canRetry:
                        return self.queue.complete(jobData, outcome: .retry)
                    case .failure:
                        return self.queue.complete(jobData, outcome: .failed)
                            .map { job.finished(result: result) }
                    }
                }
                .flatMap { self.runNext() }
        } catch {
            return .new(error: error)
        }
    }
}
