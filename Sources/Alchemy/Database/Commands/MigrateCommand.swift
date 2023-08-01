/// Migrate a database.
struct MigrateCommand: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate")
    }

    func start() async throws {
        try await DB.migrate()
    }
}
