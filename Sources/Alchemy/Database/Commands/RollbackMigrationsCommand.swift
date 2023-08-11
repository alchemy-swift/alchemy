/// Rollback migrations on a database.
struct RollbackMigrationsCommand: Command {
    static var name = "migrate:rollback"

    func start() async throws {
        try await DB.rollback()
    }
}
