import NIOCore
import NIOConcurrencyHelpers

/// A service for scheduling recurring work, in lieu of a separate
/// cron task running apart from your server.
public final class Scheduler {
    private struct WorkItem {
        let interval: Interval
        let work: () async throws -> Void
    }

    public private(set) var isStarted: Bool = false
    public private(set) var isShutdown: Bool = false
    private var workItems: [WorkItem] = []
    private let isTesting: Bool
    private var scheduled: [Scheduled<Void>]
    private let lock: NIOLock

    /// Initialize this Scheduler, potentially flagging it for testing. If
    /// testing is enabled, work items will only be run once, and not
    /// rescheduled.
    init(isTesting: Bool = false) {
        self.isTesting = isTesting
        self.scheduled = []
        self.lock = NIOLock()
    }
    
    /// Start scheduling with the given loop.
    ///
    /// - Parameter scheduleLoop: A loop to run all tasks on. Defaults
    ///   to the next available `EventLoop`.
    public func start(on scheduleLoop: EventLoop = LoopGroup.next()) {
        guard !isStarted else {
            Log.warning("This scheduler has already been started.")
            return
        }
        
        isStarted = true
        for item in workItems {
            schedule(interval: item.interval, task: item.work, on: scheduleLoop)
        }
    }

    public func shutdown() async throws {
        lock.withLock {
            isShutdown = true
            scheduled.forEach { $0.cancel() }
            scheduled = []
        }
    }

    /// Add a work item to this scheduler. When the schedule is
    /// started, it will begin running each of it's work items
    /// at their given frequency.
    ///
    /// - Parameters:
    ///   - schedule: The schedule to run this work.
    ///   - work: The work to run.
    func addWork(interval: Interval, work: @escaping () async throws -> Void) {
        workItems.append(WorkItem(interval: interval, work: work))
    }
    
    private func schedule(interval: Interval, task: @escaping () async throws -> Void, on loop: EventLoop) {
        guard let delay = interval.next() else {
            Log.info("Interval complete; there is no future date to run.")
            return
        }

        lock.withLock {
            guard !isShutdown else {
                Log.debug("Not scheduling work, the Scheduler has been shut down.")
                return
            }

            let scheduledTask = loop.flatScheduleTask(in: delay) {
                loop.asyncSubmit {
                    // Schedule next and run
                    if !self.isTesting {
                        self.schedule(interval: interval, task: task, on: loop)
                    }

                    try await task()
                }
            }

            scheduled.append(scheduledTask)
        }
    }
}
