import ArgumentParser

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
struct QueueCommand<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "queue")
    }
    
    /// The channels this worker should observe, separated by comma
    /// and ordered by priority. Defaults to "default"; the default
    /// channel of a queue.
    @Option var channels: String = kDefaultQueueChannel
    /// The number of Queue workers that should be kicked off in
    /// this process.
    @Option var workers: Int = 1
    /// Should the scheduler run in process, scheduling any recurring
    /// work.
    @Flag var schedule: Bool = false
    
    // MARK: ParseableCommand
    
    func run() throws {
        try A().launch(self)
    }
}

extension QueueCommand: Runner {
    func register(lifecycle: ServiceLifecycle) {
        lifecycle.registerWorkers(workers, channels: channels.components(separatedBy: ","))
        if schedule { 
            lifecycle.registerScheduler() 
        }

        let schedulerText = schedule ? "scheduler and " : ""
        Log.info("[Queue] started \(schedulerText)\(workers) workers.")
    }
}

extension ServiceLifecycle {
    func registerWorkers(_ count: Int, channels: [String] = [kDefaultQueueChannel]) {
        for worker in 0..<count {
            register(
                label: "Worker\(worker)",
                start: .eventLoopFuture {
                    Services.eventLoopGroup.next()
                        .submit { self.startWorker(channels: channels) }
                },
                shutdown: .none
            )
        }
    }
    
    private func startWorker(channels: [String]) {
        Services.queue.startQueueWorker(for: channels)
    }
    
    func registerScheduler() {
        register(
            label: "Scheduler",
            start: .sync { Services.scheduler.start() },
            shutdown: .none
        )
    }
}

