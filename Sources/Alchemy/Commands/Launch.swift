import ArgumentParser

/// Command to launch a given application & either serve or migrate.
public struct Launch<A: Application>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "A utility for serving or migrating an alchemy application.",
            subcommands: [ServeCommand<A>.self, MigrateCommand<A>.self, QueueCommand<A>.self],
            defaultSubcommand: ServeCommand<A>.self
        )
    }
    
    public init() {}
}
