import Foundation
import Dispatch
import NIO

/// Monitors a Queue for jobs to dequeue and run.
public protocol QueueWorker {}

extension QueueWorker {
    /// Start monitoring a queue for jobs to run.
    public func startQueueWorker(
        for queue: Queue = Services.queue,
        named queueName: String = kDefaultQueueName,
        pollRate: TimeAmount = .seconds(1),
        on eventLoop: EventLoop = Services.eventLoop
    ) {
        eventLoop.execute {
            self.runNext(on: queue, named: queueName)
                .whenComplete { _ in
                    // Run check again in the `pollRate`.
                    eventLoop.scheduleTask(in: pollRate) {
                        self.startQueueWorker(for: queue, named: queueName, pollRate: pollRate, on: eventLoop)
                    }
                }
        }
    }

    private func runNext(on queue: Queue, named queueName: String) -> EventLoopFuture<Void> {
        queue.dequeue(from: queueName)
            .flatMap { jobData in
                guard let jobData = jobData else {
                    return .new()
                }
                
                return self.execute(jobData, queue: queue)
            }
    }

    private func execute(_ jobData: JobData, queue: Queue) -> EventLoopFuture<Void> {
        do {
            let job = try JobDecoding.decode(jobData)
            return job.run()
                .flatMapAlways { result in
                    var jobData = jobData
                    jobData.attempts += 1
                    switch result {
                    case .success:
                        return queue.complete(jobData, outcome: .success)
                            .map { job.finished(result: result) }
                    case .failure where jobData.canRetry:
                        return queue.complete(jobData, outcome: .retry)
                    case .failure:
                        return queue.complete(jobData, outcome: .failed)
                            .map { job.finished(result: result) }
                    }
                }
                .flatMap { self.runNext(on: queue, named: jobData.queueName) }
        } catch {
            return .new(error: error)
        }
    }
}
