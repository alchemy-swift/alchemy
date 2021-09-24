import ArgumentParser
import Lifecycle

/// Command to launch a given application.
struct Launch: ParsableCommand {
    @Locked static var userCommands: [Command.Type] = []
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "Run an Alchemy app.",
            subcommands: [
                // Running
                RunServe.self,
                RunMigrate.self,
                RunQueue.self,
                
                // Make
                MakeController.self,
                MakeMiddleware.self,
                MakeMigration.self,
                MakeModel.self,
                MakeJob.self,
                MakeView.self,
            ] + userCommands,
            defaultSubcommand: RunServe.self
        )
    }
    
    /// The environment file to load. Defaults to `env`.
    ///
    /// This is a bit hacky since the env is actually parsed and set
    /// in App.main, but this adds the validation for it being
    /// entered properly.
    @Option(name: .shortAndLong) var env: String = "env"
}
