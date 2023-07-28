struct RunRefresh: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate:refresh")
    }

    func start() async throws {
        try await DB.reset()
        try await DB.migrate()
    }
}
