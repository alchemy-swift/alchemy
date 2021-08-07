import NIO

extension Application {
    public func schedule(job: Job, queue: Queue = .default, channel: String = Queue.defaultChannel) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Scheduler.default
                .addWork(schedule: schedule) {
                    _ = $0.flatSubmit { () -> EventLoopFuture<Void> in
                        return job.dispatch(on: queue, channel: channel)
                            .flatMapErrorThrowing {
                                Log.error("[Scheduler] error scheduling Job: \($0)")
                                throw $0
                            }
                    }
                }
        }
    }
    
    public func schedule(future: @escaping () -> EventLoopFuture<Void>) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Scheduler.default
                .addWork(schedule: schedule) {
                    _ = $0.flatSubmit(future)
                }
        }
    }
    
    public func schedule(task: @escaping () throws -> Void) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Scheduler.default.addWork(schedule: schedule, work: { _ in try task() })
        }
    }
}
