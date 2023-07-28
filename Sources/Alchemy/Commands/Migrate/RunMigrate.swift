import ArgumentParser
import Lifecycle

/// Command to run migrations when launched. This is a subcommand of
/// `Launch`.
struct RunMigrate: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate")
    }
    
    static var logStartAndFinish: Bool = false
    
    func start() async throws {
        try await DB.migrate()
    }
    
    func shutdown() async throws {
        Log.info("[Migration] Successfully applied migrations.")
    }
}

struct RunMigrateRollback: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate:rollback")
    }

    static var logStartAndFinish: Bool = false

    func start() async throws {
        try await DB.rollbackMigrations()
    }

    func shutdown() async throws {
        Log.info("[Migration] Successfully rolled back migrations.")
    }
}
