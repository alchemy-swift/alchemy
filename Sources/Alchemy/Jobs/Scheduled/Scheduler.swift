public final class Scheduler {
    private struct WorkItem {
        let schedule: Schedule
        let work: (EventLoop) throws -> Void
    }
    
    private var workItems: [WorkItem] = []
    private var isStarted: Bool = false
    
    public func start(on scheduleLoop: EventLoop = Services.eventLoopGroup.next()) {
        guard !isStarted else {
            return Log.warning("[Scheduler] this scheduler has already been started.")
        }
        
        isStarted = true
        for item in workItems {
            schedule(schedule: item.schedule, task: item.work, on: scheduleLoop)
        }
    }
    
    private func schedule(schedule: Schedule, task: @escaping (EventLoop) throws -> Void, on loop: EventLoop) {
        guard let next = schedule.next()?.date else {
            return Log.error("schedule doesn't have a future date to run.")
        }

        func scheduleNextAndRun() throws -> Void {
            self.schedule(schedule: schedule, task: task, on: loop)
            try task(loop)
        }

        let delay = Int64(next.timeIntervalSinceNow * 1000)
        loop.scheduleTask(in: .milliseconds(delay), scheduleNextAndRun)
    }
    
    fileprivate func addWork(schedule: Schedule, work: @escaping (EventLoop) throws -> Void) {
        workItems.append(WorkItem(schedule: schedule, work: work))
    }
}

extension Application {
    public func schedule(
        job: Job,
        queue: Queue = Services.queue,
        channel: String = kDefaultQueueChannel
    ) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Services.scheduler
                .addWork(schedule: schedule) {
                    _ = $0.flatSubmit { () -> EventLoopFuture<Void> in
                        return job.dispatch(on: queue, channel: channel)
                    }
                }
        }
    }
    
    public func schedule(future: @escaping () -> EventLoopFuture<Void>) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Services.scheduler
                .addWork(schedule: schedule) {
                    _ = $0.flatSubmit(future)
                }
        }
    }
    
    public func schedule(task: @escaping () throws -> Void) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Services.scheduler.addWork(schedule: schedule, work: { _ in try task() })
        }
    }
}
