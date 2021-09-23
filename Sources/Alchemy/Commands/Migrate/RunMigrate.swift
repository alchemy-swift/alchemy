import ArgumentParser
import Lifecycle

/// Command to run migrations when launched. This is a subcommand of
/// `Launch`.
struct RunMigrate: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate")
    }
    
    static var shutdownAfterRun: Bool = true
    
    /// Whether migrations should be run or rolled back. If this is
    /// false (default) then all new migrations will have their
    /// `.up` functions applied to `Database.default`. If this is
    /// true, the last batch will be have their `.down`
    /// functions applied.
    @Flag(help: "Should migrations be rolled back")
    var rollback: Bool = false
    
    // MARK: Command
    
    func start() -> EventLoopFuture<Void> {
        // Run on event loop
        Loop.group.next()
            .flatSubmit(rollback ? Database.default.rollbackMigrations : Database.default.migrate)
    }
    
    func shutdown() -> EventLoopFuture<Void> {
        let action = rollback ? "migration rollback" : "migrations"
        Log.info("[Migration] \(action) finished, shutting down.")
        return .new()
    }
}
