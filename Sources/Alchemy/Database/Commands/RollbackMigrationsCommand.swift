/// Rollback migrations on a database.
struct RollbackMigrationsCommand: Command {
    static var name = "migrate:rollback"

    func run() async throws {
        try await DB.rollback()
    }
}
