import ArgumentParser

/// Command to run migrations when launched. This is a subcommand of
/// `Launch`.
struct Migrate<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate")
    }
    
    /// Whether migrations should be run or rolled back. If this is
    /// false (default) then all new migrations will have their
    /// `.up` functions applied to `Services.db`. If this is
    /// true, the last batch will be have their `.down`
    /// functions applied.
    @Flag(help: "Should migrations be rolled back")
    var rollback: Bool = false
    
    // MARK: ParseableCommand
    
    func run() throws {
        try A().launch(MigrateRunner(rollback: self.rollback))
    }
}
