/// Rollback all migrations on your database.
struct ResetMigrationsCommand: Command {
    static var name = "migrate:reset"

    func run() async throws {
        try await DB.reset()
    }
}
