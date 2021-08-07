public final class Scheduler: Service {
    private struct WorkItem {
        let schedule: Schedule
        let work: (EventLoop) throws -> Void
    }
    
    private var workItems: [WorkItem] = []
    private var isStarted: Bool = false
    
    public func start(on scheduleLoop: EventLoop = Loop.group.next()) {
        guard !isStarted else {
            return Log.warning("[Scheduler] this scheduler has already been started.")
        }
        
        isStarted = true
        for item in workItems {
            schedule(schedule: item.schedule, task: item.work, on: scheduleLoop)
        }
    }
    
    private func schedule(schedule: Schedule, task: @escaping (EventLoop) throws -> Void, on loop: EventLoop) {
        guard 
            let next = schedule.next(),
            let nextDate = next.date
        else {
            return Log.error("schedule doesn't have a future date to run.")
        }

        func scheduleNextAndRun() throws -> Void {
            self.schedule(schedule: schedule, task: task, on: loop)
            try task(loop)
        }

        var delay = Int64(nextDate.timeIntervalSinceNow * 1000)
        // Occasionally Cron library returns the `next()` as fractions of a 
        // millisecond before or after now. If the delay is 0, get the next
        // date and use that instead.
        if delay == 0 {
            let newDate = schedule.next(next)?.date ?? Date().addingTimeInterval(1)
            delay = Int64(newDate.timeIntervalSinceNow * 1000)
        }
        loop.scheduleTask(in: .milliseconds(delay), scheduleNextAndRun)
    }
    
    func addWork(schedule: Schedule, work: @escaping (EventLoop) throws -> Void) {
        workItems.append(WorkItem(schedule: schedule, work: work))
    }
}
