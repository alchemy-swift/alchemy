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
                
                Log.debug("Dequeued job \(jobData.jobName) from queue \(jobData.queueName)")
                return self.execute(jobData, queue: queue)
            }
    }

    private func execute(_ jobData: JobData, queue: Queue) -> EventLoopFuture<Void> {
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
                return queue.complete(jobData, outcome: .success)
            case .failure where jobData.canRetry:
                return queue.complete(jobData, outcome: .retry)
            case .failure:
                return queue.complete(jobData, outcome: .failed)
            }
        }
        .flatMap { self.runNext(on: queue, named: jobData.queueName) }
    }
}
