import NIOCore
import NIOConcurrencyHelpers

/// A service for scheduling recurring work, in lieu of a separate cron task
/// running apart from your server.
public final class Scheduler {
    private struct ScheduledTask {
        let name: String
        let frequency: Frequency
        let work: () async throws -> Void
    }

    public private(set) var isStarted: Bool = false
    private var tasks: [ScheduledTask] = []
    private var scheduled: [Scheduled<Void>] = []
    private let lock = NIOLock()

    /// Start scheduling with the given loop.
    ///
    /// - Parameter scheduleLoop: A loop to run all tasks on. Defaults to the
    ///   next available `EventLoop`.
    public func start(on scheduleLoop: EventLoop = LoopGroup.next()) {
        guard lock.withLock({
            guard !isStarted else { return false }
            isStarted = true
            return true
        }) else {
            Log.warning("This scheduler has already been started.")
            return
        }

        for task in tasks {
            schedule(task: task, on: scheduleLoop)
        }
    }

    public func shutdown() async throws {
        lock.withLock {
            isStarted = false
            scheduled.forEach { $0.cancel() }
            scheduled = []
        }
    }

    private func schedule(task: ScheduledTask, on loop: EventLoop) {
        guard let delay = task.frequency.timeUntilNext() else {
            Log.info("Scheduling \(task.name) complete; there are no future times in the frequency.")
            return
        }

        lock.withLock {
            guard isStarted else {
                Log.debug("Not scheduling task \(task.name), this Scheduler is not started.")
                return
            }

            let scheduledTask = loop.flatScheduleTask(in: delay) {
                loop.asyncSubmit {
                    // Schedule next and run
                    self.schedule(task: task, on: loop)

                    try await task.work()
                }
            }

            scheduled.append(scheduledTask)
        }
    }

    // MARK: Scheduling

    /// Schedule a recurring task.
    ///
    /// - Parameters:
    ///   - name: An optional name of the task for debugging.
    ///   - task: The task to run.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func task(_ name: String? = nil, _ task: @escaping () async throws -> Void) -> Frequency {
        let frequency = Frequency()
        let name = name ?? "task_\(tasks.count)"
        let task = ScheduledTask(name: name, frequency: frequency) {
            do {
                Log.info("Scheduling \(name) (\(frequency.cron.string))")
                try await task()
            } catch {
                Log.error("Error scheduling \(name): \(error)")
                throw error
            }
        }
        
        tasks.append(task)
        return frequency
    }

    /// Schedule a recurring `Job`.
    ///
    /// - Parameters:
    ///   - job: The job to schedule.
    ///   - queue: The queue to schedule it on.
    ///   - channel: The queue channel to schedule it on.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func job<J: Job>(_ job: @escaping @autoclosure () -> J, queue: Queue = Q, channel: String = Queue.defaultChannel) -> Frequency {

        // Register the job, just in case the user forgot.
        Jobs.register(J.self)

        return task("\(J.self)") {
            try await job().dispatch(on: queue, channel: channel)
        }
    }
}
