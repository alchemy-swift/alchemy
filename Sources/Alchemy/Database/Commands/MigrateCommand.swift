/// Migrate a database.
struct MigrateCommand: Command {
    static var name = "migrate"

    func run() async throws {
        try await DB.migrate()
    }
}
