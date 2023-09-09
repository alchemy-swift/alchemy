/// Command to run queue workers.
struct ScheduleCommand: Command {
    static var name = "schedule"
    static var runUntilStopped: Bool = true

    // MARK: Command

    func run() throws {
        @Inject var app: Application
        app.schedule(on: Schedule)
        Schedule.start()
        Log.info("Started scheduler.")
    }
}
