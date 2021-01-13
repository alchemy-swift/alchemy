import ArgumentParser

/// Command to launch a given application & either serve or migrate.
public struct Launch<A: Application>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "A utility for serving or migrating an alchemy application.",
            subcommands: [Serve<A>.self, Migrate<A>.self],
            defaultSubcommand: Serve<A>.self
        )
    }
    
    public init() {}
}

extension Application {
    /// Launch this application. By default it serves, see `Launch`
    /// for subcommands and options. Call this in the `main.swift`
    /// of your project.
    public static func launch() {
        Launch<Self>.main()
    }
}
