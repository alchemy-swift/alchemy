import ArgumentParser
import Lifecycle

final class Commander {
    /// Command to launch a given application.
    private struct Launch: AsyncParsableCommand {
        static var configuration: CommandConfiguration {
            Container.resolveAssert(Commander.self).launchConfiguration()
        }

        /// The environment file to load. Defaults to `env`.
        @Option(name: .shortAndLong) var env: String = "env"

        /// The environment file to load. Defaults to `env`.
        @Option(name: .shortAndLong) var log: Logger.Level? = nil
    }

    @Inject var env: Environment

    var commands: [Command.Type] = []
    var defaultCommand: Command.Type = ServeCommand.self

    func start(args: [String]? = nil) async throws {
        do {
            // When running tests, don't use the command line args as the default;
            // they are irrelevant to running the app and may contain a bunch of
            // options that will cause `AsyncParsableCommand` parsing to fail.
            let fallbackArgs = env.isTest ? [] : Array(CommandLine.arguments.dropFirst())
            var command = try Launch.parseAsRoot(args ?? fallbackArgs)
            if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
        } catch {
            Launch.exit(withError: error)
        }
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

extension Logger.Level: ExpressibleByArgument {}
