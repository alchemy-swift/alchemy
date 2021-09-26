import NIO

extension Application {
    /// Schedule a recurring `Job`.
    ///
    /// - Parameters:
    ///   - job: The job to schedule.
    ///   - queue: The queue to schedule it on.
    ///   - channel: The queue channel to schedule it on.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func schedule(job: Job, queue: Queue = .default, channel: String = Queue.defaultChannel) -> ScheduleBuilder {
        ScheduleBuilder(.default) {
            do {
                try await job.dispatch(on: queue, channel: channel).get()
            } catch {
                Log.error("[Scheduler] error scheduling Job: \(error)")
                throw error
            }
        }
    }
    
    /// Schedule a recurring task.
    ///
    /// - Parameter task: The task to run.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func schedule(task: @escaping () async throws -> Void) -> ScheduleBuilder {
        ScheduleBuilder { try await task() }
    }
}

private extension ScheduleBuilder {
    init(_ scheduler: Scheduler = .default, work: @escaping () async throws -> Void) {
        self.init {
            scheduler.addWork(schedule: $0, work: work)
        }
    }
}
