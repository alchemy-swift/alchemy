/// Rollback all migrations on your database.
struct ResetMigrationsCommand: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate:reset")
    }

    func start() async throws {
        try await DB.reset()
    }
}
