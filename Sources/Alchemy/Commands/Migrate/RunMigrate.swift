/// Migrate a database.
struct RunMigrate: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate")
    }

    func start() async throws {
        try await DB.migrate()
    }
}
