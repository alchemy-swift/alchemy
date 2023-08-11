struct RefreshMigrationsCommand: Command {
    static var name = "migrate:refresh"

    func start() async throws {
        try await DB.reset()
        print()
        try await DB.migrate()
        print()
    }
}
