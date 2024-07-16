/// Command to run queue workers.
struct ScheduleCommand: Command {
    static var name = "schedule"

    // MARK: Command

    func run() async throws {
        Schedule.start()
        try await gracefulShutdown()
    }
}
