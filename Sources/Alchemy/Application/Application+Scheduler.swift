import NIO

extension Application {
    /// Schedule a recurring `Job`.
    ///
    /// - Parameters:
    ///   - job: The job to schedule.
    ///   - queue: The queue to schedule it on.
    ///   - channel: The queue channel to schedule it on.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func schedule(job: @escaping @autoclosure () -> Job, queue: Queue = .default, channel: String = Queue.defaultChannel) -> Schedule {
        Schedule {
            Scheduler.default.addWork(schedule: $0) {
                do {
                    try await job().dispatch(on: queue, channel: channel)
                } catch {
                    Log.error("[Scheduler] error scheduling Job: \(error)")
                    throw error
                }
            }
        }
    }
    
    /// Schedule a recurring task.
    ///
    /// - Parameter task: The task to run.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func schedule(task: @escaping () async throws -> Void) -> Schedule {
        Schedule {
            Scheduler.default.addWork(schedule: $0) {
                try await task()
            }
        }
    }
}
