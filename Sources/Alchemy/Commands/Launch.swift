import ArgumentParser
import Lifecycle

/// Command to launch a given application.
struct Launch: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "A utility for running an Alchemy command.",
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
            ],
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
