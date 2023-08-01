/// Rollback migrations on a database.
struct RollbackMigrationsCommand: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate:rollback")
    }

    func start() async throws {
        try await DB.rollback()
    }
}
