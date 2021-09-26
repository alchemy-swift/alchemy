/// A service for scheduling recurring work, in lieu of a separate
/// cron task running apart from your server.
public final class Scheduler: Service {
    private struct WorkItem {
        let schedule: Schedule
        let work: () async throws -> Void
    }
    
    private var workItems: [WorkItem] = []
    private var isStarted: Bool = false
    
    /// Start scheduling with the given loop.
    ///
    /// - Parameter scheduleLoop: A loop to run all tasks on. Defaults
    ///   to the next available `EventLoop`.
    public func start(on scheduleLoop: EventLoop = Loop.group.next()) {
        guard !isStarted else {
            return Log.warning("[Scheduler] this scheduler has already been started.")
        }
        
        isStarted = true
        for item in workItems {
            schedule(schedule: item.schedule, task: item.work, on: scheduleLoop)
        }
    }
    
    /// Add a work item to this scheduler. When the schedule is
    /// started, it will begin running each of it's work items
    /// at their given frequency.
    ///
    /// - Parameters:
    ///   - schedule: The schedule to run this work.
    ///   - work: The work to run.
    func addWork(schedule: Schedule, work: @escaping () async throws -> Void) {
        workItems.append(WorkItem(schedule: schedule, work: work))
    }
    
    @Sendable
    private func schedule(schedule: Schedule, task: @escaping () async throws -> Void, on loop: EventLoop) {
        guard let next = schedule.next(), let nextDate = next.date else {
            return Log.error("[Scheduler] schedule doesn't have a future date to run.")
        }

        @Sendable
        func scheduleNextAndRun() async throws -> Void {
            self.schedule(schedule: schedule, task: task, on: loop)
            try await task()
        }

        var delay = Int64(nextDate.timeIntervalSinceNow * 1000)
        // Occasionally Cron library returns the `next()` as fractions of a 
        // millisecond before or after now. If the delay is 0, get the next
        // date and use that instead.
        if delay == 0 {
            let newDate = schedule.next(next)?.date ?? Date().addingTimeInterval(1)
            delay = Int64(newDate.timeIntervalSinceNow * 1000)
        }
        
        let elp = loop.makePromise(of: Void.self)
        elp.completeWithTask {
            try await scheduleNextAndRun()
        }
        
        loop.flatScheduleTask(in: .milliseconds(delay)) { elp.futureResult }
    }
}
