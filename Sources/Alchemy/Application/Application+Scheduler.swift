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
            _ = $0.flatSubmit { () -> EventLoopFuture<Void> in
                return job.dispatch(on: queue, channel: channel)
                    .flatMapErrorThrowing {
                        Log.error("[Scheduler] error scheduling Job: \($0)")
                        throw $0
                    }
            }
        }
    }
    
    /// Schedule a recurring asynchronous task.
    ///
    /// - Parameter future: The async task to run.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func schedule(future: @escaping () -> EventLoopFuture<Void>) -> ScheduleBuilder {
        ScheduleBuilder(.default) {
            _ = $0.flatSubmit(future)
        }
    }
    
    /// Schedule a recurring synchronous task.
    ///
    /// - Parameter future: The async task to run.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func schedule(task: @escaping () throws -> Void) -> ScheduleBuilder {
        ScheduleBuilder(.default) { _ in try task() }
    }
}

private extension ScheduleBuilder {
    init(_ scheduler: Scheduler = .default, work: @escaping (EventLoop) throws -> Void) {
        self.init {
            scheduler.addWork(schedule: $0, work: work)
        }
    }
}
