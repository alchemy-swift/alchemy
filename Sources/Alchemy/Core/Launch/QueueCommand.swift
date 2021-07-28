import ArgumentParser

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
struct QueueCommand<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "queue")
    }
    
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
        if schedule {
            lifecycle.registerScheduler()
        }
        
        lifecycle.registerWorkers(workers)
    }
}

extension ServiceLifecycle {
    func registerWorkers(_ count: Int) {
        for worker in 0..<count {
            register(
                label: "Worker\(worker)",
                start: .eventLoopFuture {
                    Services.eventLoopGroup.next()
                        .submit(startWorker)
                },
                shutdown: .none
            )
        }
    }
    
    private func startWorker() {
        Services.queue.startQueueWorker()
    }
    
    func registerScheduler() {
        register(
            label: "Scheduler",
            start: .sync { Services.scheduler.start() },
            shutdown: .none
        )
    }
}

