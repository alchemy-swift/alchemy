import Foundation
import Dispatch
import NIO

struct TestJob: Job {

    func run() -> EventLoopFuture<Void> {
        print("The message from this job is")
        return EventLoopFuture.new()
    }

}

public struct JobType<T: Job> {
    let type: T.Type
}

public final class Worker {

    private let eventLoop: EventLoop

    private let queue: Queue

    private let refreshInterval: TimeAmount = .seconds(1)

    private var types: [String: JobType<Any: Job>] = [:]

    public init(eventLoop: EventLoop, queue: Queue, types: [JobType<Job>]) throws {
        self.eventLoop = eventLoop
        self.queue = queue

        for job in types {

            self.types[job.type.name] = job
        }
    }

    public func add(type: JobType<Job>) {
        self.types[type.name] = type
    }

    /// Atomically transfers a task from the work queue into the
    /// processing queue then enqueues it to the worker.

    public func run() -> Worker {
        self.eventLoop.scheduleRepeatedAsyncTask(
            initialDelay: .seconds(0),
            delay: refreshInterval
        ) { task in
            // run task
            return self.runNext().map {
                //Check if shutting down
                //                if self.isShuttingDown.load() {
                //                    task.cancel()
                //                }
            }.recover { error in
                print("Job run failed: \(error)")
            }
        }
        return self
    }

    private func runNext() -> EventLoopFuture<Void> {
        queue.dequeue()
            .flatMap { item in
                //No job found, go to the next iteration
                guard let item = item else {
                    return self.queue.eventLoop.makeSucceededFuture(())
                }
                return self.execute(item)
        }
    }

    private func execute(_ item: PersistedJob) -> EventLoopFuture<Void> {
        if item.job == nil {
            if let type = types[item.name] {
                let ttt: Job.Type = type
                try? item.loadPayload(type: ttt)
            }
        }
        item.run().flatMap {
            return self.complete(item: item)
        }
        .flatMapError { error in
            return self.failure(item, error: error)
        }
    }

    /// Called when a task is successfully completed. If the task is
    /// periodic it is re-queued into the zset.
    private func complete(item: PersistedJob) -> EventLoopFuture<Void> {
        if item.job is PeriodicJob {
            return queue.requeue(item)
        } else {
            return queue.complete(item, success: true)
        }
    }

    /// Called when the tasks fails. Note: If the tasks recovery
    /// stategy is none it will never be ran again.
    private func failure(_ item: PersistedJob, error: Error) -> EventLoopFuture<Void> {
        guard let job = item.job else { return EventLoopFuture.new() }

        job.failed(error: error)

        switch job.recoveryStrategy {
        case .none:
            return queue.complete(item, success: false)
        case .retry(let retries):
            if item.shouldRetry(retries: retries) {
                item.retry()
                return queue.requeue(item)
            }
            else {
                return queue.complete(item, success: false)
            }
        }
    }
}
