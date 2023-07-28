/// Rollback migrations on a database.
struct RunRollback: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate:rollback")
    }

    func start() async throws {
        try await DB.rollback()
    }
}
