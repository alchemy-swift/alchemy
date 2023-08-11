/// Migrate a database.
struct MigrateCommand: Command {
    static var name = "migrate"

    func start() async throws {
        try await DB.migrate()
    }
}
