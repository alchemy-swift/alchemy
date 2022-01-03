import NIOCore

/// A service for scheduling recurring work, in lieu of a separate
/// cron task running apart from your server.
public final class Scheduler {
    private struct WorkItem {
        let schedule: Schedule
        let work: () async throws -> Void
    }

    public private(set) var isStarted: Bool = false
    private var workItems: [WorkItem] = []
    private let isTesting: Bool
    
    /// Initialize this Scheduler, potentially flagging it for testing. If
    /// testing is enabled, work items will only be run once, and not
    /// rescheduled.
    init(isTesting: Bool = false) {
        self.isTesting = isTesting
    }
    
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
    
    private func schedule(schedule: Schedule, task: @escaping () async throws -> Void, on loop: EventLoop) {
        guard let delay = schedule.next() else {
            return Log.info("[Scheduler] scheduling finished; there's no future date to run.")
        }
        
        loop.flatScheduleTask(in: delay) {
            loop.asyncSubmit {
                // Schedule next and run
                if !self.isTesting {
                    self.schedule(schedule: schedule, task: task, on: loop)
                }
                
                try await task()
            }
        }
    }
}
