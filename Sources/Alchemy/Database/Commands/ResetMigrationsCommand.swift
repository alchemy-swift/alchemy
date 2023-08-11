/// Rollback all migrations on your database.
struct ResetMigrationsCommand: Command {
    static var name = "migrate:reset"

    func start() async throws {
        try await DB.reset()
    }
}
