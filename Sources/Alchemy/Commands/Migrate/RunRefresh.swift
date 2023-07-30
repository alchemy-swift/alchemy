struct RunRefresh: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate:refresh")
    }

    func start() async throws {
        Log.info("Rolling back migrations.")
        try await DB.reset()
        print()
        Log.info("Running migrations.")
        try await DB.migrate()
        print()
    }
}
