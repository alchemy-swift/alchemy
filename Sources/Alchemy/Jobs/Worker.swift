import Foundation
import Dispatch
import NIO

final class Worker {

    private let eventLoop: EventLoop

    private let queue: Queue

    private let refreshInterval: Int

    private let types: [String: Job.Type]

    init(eventLoop: EventLoop, queue: Queue, types: [Job.Type]) throws {
        self.queue = queue

        for job in types {
            self.types[job.name] = job
        }
    }

    public func add(type: Job.Type) {
        self.types[type.name] = type
    }

    /// Atomically transfers a task from the work queue into the
    /// processing queue then enqueues it to the worker.

    public func run() -> EventLoopFuture<Void> {
        let task = self.eventLoop.scheduleRepeatedAsyncTask(
            initialDelay: .seconds(0),
            delay: .seconds(refreshInterval)
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
    }

    private func runNext() -> EventLoopFuture<Void> {
        let type =
        self.queue.dequeue(mapper: {})
            .flatMap { id in
                //No job found, go to the next iteration
                guard let id = id else {
                    return self.queue.eventLoop.makeSucceededFuture(())
                }
                self.execute(job)
        }
    }

    private func execute(_ job: Job) {
        job.run().flatMap {
            complete(job: job)
        }
        .flatMapError { error in

            failure(job, error: $0)
        }
    }

    /// Called when a task is successfully completed. If the task is
    /// periodic it is re-queued into the zset.
    private func complete(job: Job) {
        if let job = job as? PeriodicJob {
            let box = try PeriodicBox(task)
            try queue.requeue(item: box, success: true)
        } else {
            try queue.complete(item: EnqueueingBox(task), success: true)
        }
    }


    /// Called when the tasks fails. Note: If the tasks recovery
    /// stategy is none it will never be ran again.
    private func failure(_ job: Job, error: Error) {
        switch job.recoveryStrategy {
        case .none:
            try queue.complete(item: , success: false)
        case .retry(let retries):
            if task.shouldRetry(retries) {
                task.retry()
                try queue.requeue(item: EnqueueingBox(task), success: false)
            } else {
                try queue.complete(item: EnqueueingBox(task), success: false)
            }
        }
    }
}
