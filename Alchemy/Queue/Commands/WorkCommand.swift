/// Command to run queue workers.
struct WorkCommand: Command {
    static var name = "queue:work"
    static var runUntilStopped: Bool = true

    /// The name of the queue the workers should observe. If no name is given,
    /// workers will observe the default queue.
    @Option var name: String?
    
    /// The channels this worker should observe, separated by comma and ordered
    /// by priority. Defaults to "default"; the default channel of a queue.
    @Option(name: .shortAndLong) var channels: String = Queue.defaultChannel
    
    /// The number of Queue workers that should be kicked off in this process.
    @Option var workers: Int = 1
    
    /// Should the scheduler run in process, scheduling any recurring work.
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
        let queue: Queue = name.map { Container.require(id: $0) } ?? Q
        for _ in 0..<workers {
            queue.startWorker(for: channels.components(separatedBy: ","))
        }

        if schedule {
            Schedule.start()
        }
        
        let schedulerText = schedule ? "scheduler and " : ""
        Log.info("Started \(schedulerText)\(workers) Queue workers.")
    }
}
