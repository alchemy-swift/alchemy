struct RefreshMigrationsCommand: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate:refresh")
    }

    func start() async throws {
        try await DB.reset()
        print()
        try await DB.migrate()
        print()
    }
}
