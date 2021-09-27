import ArgumentParser
import Lifecycle

/// Command to run migrations when launched. This is a subcommand of
/// `Launch`.
struct RunMigrate: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate")
    }
    
    static var logStartAndFinish: Bool = false
    
    /// Whether migrations should be run or rolled back. If this is
    /// false (default) then all new migrations will have their
    /// `.up` functions applied to `Database.default`. If this is
    /// true, the last batch will be have their `.down`
    /// functions applied.
    @Flag(help: "Should migrations be rolled back")
    var rollback: Bool = false
    
    // MARK: Command
    
    func start() async throws {
        if rollback {
            try await Database.default.rollbackMigrations()
        } else {
            try await Database.default.migrate()
        }
    }
    
    func shutdown() async throws {
        let action = rollback ? "migration rollback" : "migrations"
        Log.info("[Migration] \(action) finished, shutting down.")
    }
}
