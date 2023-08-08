import ArgumentParser
import Lifecycle

/// Command to run queue workers.
struct WorkCommand: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "queue:work")
    }
    
    static var shutdownAfterRun: Bool = false
    
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
    
    init() {}
    init(name: String?, channels: String = Queue.defaultChannel, workers: Int = 1, schedule: Bool = false) {
        self.name = name
        self.channels = channels
        self.workers = workers
        self.schedule = schedule
    }
    
    // MARK: Command
    
    func run() throws {
        let queue: Queue = name.map { Container.resolveAssert(identifier: $0) } ?? Q

        @Inject var lifecycle: ServiceLifecycle
        lifecycle.registerWorkers(workers, on: queue, channels: channels.components(separatedBy: ","))
        if schedule {
            lifecycle.registerScheduler()
        }
        
        let schedulerText = schedule ? "scheduler and " : ""
        Log.info("[Queue] started \(schedulerText)\(workers) workers.")
    }
    
    func start() {}
}

extension ServiceLifecycle {
    private var scheduler: Scheduler { Container.resolveAssert() }
    
    /// Start the scheduler when the app starts.
    func registerScheduler() {
        register(label: "Scheduler", start: .sync { scheduler.start() }, shutdown: .none)
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
                start: .sync {
                    queue.startWorker(for: channels, on: LoopGroup.next())
                },
                shutdown: .none
            )
        }
    }
}

