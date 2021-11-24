import ArgumentParser
import Lifecycle

/// Command to launch a given application.
struct Launch: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "Run an Alchemy app.",
            subcommands: [
                // Running
                RunServe.self,
                RunMigrate.self,
                RunWorker.self,
                
                // Database
                SeedDatabase.self,
                
                // Make
                MakeController.self,
                MakeMiddleware.self,
                MakeMigration.self,
                MakeModel.self,
                MakeJob.self,
                MakeView.self,
            ] + customCommands,
            defaultSubcommand: RunServe.self
        )
    }
    
    @Locked static var customCommands: [Command.Type] = []
    
    /// The environment file to load. Defaults to `env`.
    ///
    /// This is a bit hacky since the env is actually parsed and set
    /// in App.main, but this adds the validation for it being
    /// entered properly.
    @Option(name: .shortAndLong) var env: String = "env"
}
