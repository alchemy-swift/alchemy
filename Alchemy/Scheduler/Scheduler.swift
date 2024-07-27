import AsyncAlgorithms
import NIOCore
import NIOConcurrencyHelpers
import Foundation
import ServiceLifecycle

/// A service for scheduling recurring work, in lieu of a separate cron task
/// running apart from your server.
public final class Scheduler {
    struct Task: Service, @unchecked Sendable {
        let name: String
        let frequency: Frequency
        let task: () async throws -> Void

        func run() async throws {
            for try await _ in frequency.cancelOnGracefulShutdown() {
                do {
                    Log.info("Scheduling \(name) (\(frequency.cron.string))")
                    try await task()
                } catch {
                    // log an error but don't throw - we don't want to stop all
                    // scheduling if a single instance of a task results in
                    // an error.
                    Log.error("Error scheduling \(name): \(error)")
                }
            }

            Log.info("Scheduling \(name) complete; there are no future times in the frequency.")
        }
    }

    var isStarted = false
    var tasks: [Task] = []

    /// Start scheduling.
    public func start() {
        isStarted = true
        Log.info("Scheduling \(tasks.count) tasks.")
        for task in tasks {
            Life.addService(task)
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
        tasks.append(
            Task(name: name ?? "task_\(tasks.count)",
                 frequency: frequency,
                 task: task)
        )
        return frequency
    }

    /// Schedule a recurring `Job`.
    ///
    /// - Parameters:
    ///   - job: The job to schedule.
    ///   - queue: The queue to schedule it on.
    ///   - channel: The queue channel to schedule it on.
    /// - Returns: A builder for customizing the scheduling frequency.
    public func job<J: Job>(_ job: @escaping @autoclosure () -> J,
                            queue: Queue = Q,
                            channel: String = Queue.defaultChannel) -> Frequency {

        // Register the job, just in case the user forgot.
        Jobs.register(J.self)

        return task("\(J.self)") {
            try await job().dispatch(on: queue, channel: channel)
        }
    }
}
