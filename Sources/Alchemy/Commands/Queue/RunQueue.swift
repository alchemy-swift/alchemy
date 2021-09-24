import ArgumentParser
import Lifecycle

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
struct RunQueue: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "queue")
    }
    
    static var shutdownAfterRun: Bool = false
    static var logStartAndFinish: Bool = false
    
    /// The name of the queue the workers should observe. If no name
    /// is given, workers will observe the default queue.
    @Option var name: String?
    
    /// The channels this worker should observe, separated by comma
    /// and ordered by priority. Defaults to "default"; the default
    /// channel of a queue.
    @Option(name: .shortAndLong) var channels: String = Queue.defaultChannel
    
    /// The number of Queue workers that should be kicked off in
    /// this process.
    @Option var workers: Int = 1
    
    /// Should the scheduler run in process, scheduling any recurring
    /// work.
    @Flag var schedule: Bool = false
    
    // MARK: Command
    
    func run() throws {
        let queue: Queue = name.map { .named($0) } ?? .default
        ServiceLifecycle.default
            .registerWorkers(workers, on: queue, channels: channels.components(separatedBy: ","))
        if schedule {
            ServiceLifecycle.default.registerScheduler()
        }

        let schedulerText = schedule ? "scheduler and " : ""
        Log.info("[Queue] started \(schedulerText)\(workers) workers.")
    }
    
    func start() -> EventLoopFuture<Void> { .new() }
}

extension ServiceLifecycle {
    /// Start the scheduler when the app starts.
    func registerScheduler() {
        register(label: "Scheduler", start: .sync { Scheduler.default.start() }, shutdown: .none)
    }
    
    /// Start queue workers when the app starts.
    ///
    /// - Parameters:
    ///   - count: The number of workers to start.
    ///   - queue: The queue they should monitor for jobs.
    ///   - channels: The channels they should monitor for jobs.
    ///     Defaults to `[Queue.defaultChannel]`.
    func registerWorkers(_ count: Int, on queue: Queue, channels: [String] = [Queue.defaultChannel]) {
        for worker in 0..<count {
            register(
                label: "Worker\(worker)",
                start: .eventLoopFuture {
                    Loop.group.next()
                        .submit { startWorker(on: queue, channels: channels) }
                },
                shutdown: .none
            )
        }
    }
    
    private func startWorker(on queue: Queue, channels: [String]) {
        queue.startWorker(for: channels)
    }
}

