import NIO

extension Scheduler {
    /// Schedule a recurring `Job`.
    ///
    /// - Parameters:
    ///   - job: The job to schedule.
    ///   - queue: The queue to schedule it on.
    ///   - channel: The queue channel to schedule it on.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func job(_ job: @escaping @autoclosure () -> Job, queue: Queue = Q, channel: String = Queue.defaultChannel) -> Schedule {
        Schedule { [weak self] schedule in
            self?.addWork(schedule: schedule) {
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
    public func run(_ task: @escaping () async throws -> Void) -> Schedule {
        Schedule { [weak self] schedule in
            self?.addWork(schedule: schedule) {
                try await task()
            }
        }
    }
}
