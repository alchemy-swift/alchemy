import Foundation
import Dispatch
import NIO

public final class Worker<T: Queue> {

    private let eventLoop: EventLoop

    private let queue: T

    private let refreshInterval: TimeAmount = .seconds(1)

    private var types: [String: AnyJob] = [:]

    public init(
        eventLoop: EventLoop = Services.eventLoop,
        queue: T,
        types: [AnyJob]
    ) {
        self.eventLoop = eventLoop
        self.queue = queue

        for job in types {
            self.types[job.name] = job
        }
    }

    public func add(type: AnyJob) {
        self.types[type.name] = type
    }

    /// Atomically transfers a task from the work queue into the
    /// processing queue then enqueues it to the worker.

    @discardableResult
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

    private func execute(_ item: T.QueueItem) -> EventLoopFuture<Void> {
        guard let task = types[item.name] else { return EventLoopFuture.new() }
        return item.run(job: task).flatMap {
            self.complete(item: item)
        }
        .flatMap {
            self.runNext()
        }
        .flatMapError { error in
            return self.failure(item, error: error)
        }
    }

    /// Called when a task is successfully completed. If the task is
    /// periodic it is re-queued into the zset.
    private func complete(item: T.QueueItem) -> EventLoopFuture<Void> {
//        if item.job is PeriodicJob {
//            return queue.requeue(item)
//        } else {
            return queue.complete(item, success: true)
//        }
    }

    /// Called when the tasks fails. Note: If the tasks recovery
    /// stategy is none it will never be ran again.
    private func failure(_ item: T.QueueItem, error: Error) -> EventLoopFuture<Void> {
        guard let task = types[item.name] else { return EventLoopFuture.new() }

        switch task.recoveryStrategy {
        case .none:
            return queue.complete(item, success: false)
        case .retry(let retries):
            if item.shouldRetry(maxRetries: retries) {
                var tempItem = item
                tempItem.retry()
                return queue.requeue(tempItem)
            }
            else {
                return queue.complete(item, success: false)
            }
        }
    }
}
