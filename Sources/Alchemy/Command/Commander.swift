import ArgumentParser
import Lifecycle

final class Commander {
    @Inject var env: Environment

    var commands: [Command.Type] = []
    var defaultCommand: Command.Type = ServeCommand.self

    func start(args: [String] = []) throws {
        // When running tests, don't use the command line args as the default;
        // they are irrelevant to running the app and may contain a bunch of
        // options that will cause `ParsableCommand` parsing to fail.
        let fallbackArgs = env.isTesting ? [] : Array(CommandLine.arguments.dropFirst())
        Launch.main(args.isEmpty ? fallbackArgs : args)

        var startupError: Error? = nil
        let semaphore = DispatchSemaphore(value: 0)
        Lifecycle.start {
            startupError = $0
            semaphore.signal()
        }

        semaphore.wait()
        if let startupError = startupError {
            throw startupError
        }

        // Blocks until the application receives a shutdown signal.
        Lifecycle.wait()
    }

    func stop() async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            Lifecycle.shutdown { error in
                if let error {
                    c.resume(throwing: error)
                } else {
                    c.resume()
                }
            }
        }
    }

    func register(command: (some Command).Type) {
        commands.append(command)
    }

    func launchConfiguration() -> CommandConfiguration {
        CommandConfiguration(abstract: "Launch your app.", subcommands: commands, defaultSubcommand: defaultCommand)
    }
}

/// Command to launch a given application.
private struct Launch: ParsableCommand {
    static var configuration: CommandConfiguration {
        Container.resolveAssert(Commander.self).launchConfiguration()
    }
    
    /// The environment file to load. Defaults to `env`.
    ///
    /// This is a bit hacky since the env is actually parsed and set in Env,
    /// but this adds the validation for it being entered properly.
    @Option(name: .shortAndLong) var env: String = "env"
}
