import ArgumentParser
import Lifecycle

final class Commander {
    /// Command to launch a given application.
    private struct Launch: AsyncParsableCommand {
        static var configuration: CommandConfiguration {
            Container.require(Commander.self).launchConfiguration()
        }

        /// The environment file to load. Defaults to `env`.
        @Option(name: .shortAndLong) var env: String = "env"

        /// The environment file to load. Defaults to `env`.
        @Option(name: .shortAndLong) var log: Logger.Level? = nil
    }

    var commands: [Command.Type] = []
    var defaultCommand: Command.Type = ServeCommand.self

    func register(command: (some Command).Type) {
        commands.append(command)
    }

    func launchConfiguration() -> CommandConfiguration {
        CommandConfiguration(abstract: "Launch your app.", subcommands: commands, defaultSubcommand: defaultCommand)
    }

    func start(args: [String]? = nil, wait: Bool) async throws {
        do {
            // 0. Parse the Command

            // When running tests, don't use the command line args as the default;
            // they are irrelevant to running the app and may contain a bunch of
            // options that will cause `AsyncParsableCommand` parsing to fail.
            let fallbackArgs = Env.isTesting ? [] : Array(CommandLine.arguments.dropFirst())
            var command = try Launch.parseAsRoot(args ?? fallbackArgs)

            // 1. Run Command

            try await LoopGroup.next()
                .asyncSubmit {
                    if var asyncCommand = command as? AsyncParsableCommand {
                        try await asyncCommand.run()
                    } else {
                        try command.run()
                    }
                }
                .get()

            // 2. Wait or Shutdown

            guard wait else {
                return
            }

            if command.waitForLifecycle {
                Lifecycle.wait()
            } else {
                try await Lifecycle.shutdown()
            }
        } catch {
            Launch.exit(withError: error)
        }
    }
}

extension Logger.Level: ExpressibleByArgument {}

extension ParsableCommand {
    fileprivate var waitForLifecycle: Bool {
        !((Self.self as? Command.Type)?.shutdownAfterRun ?? true)
    }
}
