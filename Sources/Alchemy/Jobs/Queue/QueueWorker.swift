import Foundation
import Dispatch
import NIO

extension Queue {
    /// Start monitoring a queue for jobs to run.
    public func startQueueWorker(
        named channel: String = kDefaultQueueChannel,
        pollRate: TimeAmount = .seconds(1),
        on eventLoop: EventLoop = Services.eventLoopGroup.next()
    ) {
        return eventLoop.execute {
            self.runNext(named: channel)
                .whenComplete { _ in
                    // Run check again in the `pollRate`.
                    eventLoop.scheduleTask(in: pollRate) {
                        self.startQueueWorker(named: channel, pollRate: pollRate, on: eventLoop)
                    }
                }
        }
    }

    private func runNext(named channel: String) -> EventLoopFuture<Void> {
        dequeue(from: channel)
            .flatMap { jobData in
                guard let jobData = jobData else {
                    return .new()
                }
                
                Log.debug("Dequeued job \(jobData.jobName) from queue \(jobData.channel)")
                return self.execute(jobData)
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
                return self.complete(jobData, outcome: .retry)
            case .failure:
                return self.complete(jobData, outcome: .failed)
            }
        }
        .flatMap { self.runNext(named: jobData.channel) }
    }
}
