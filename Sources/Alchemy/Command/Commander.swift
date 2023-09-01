import ArgumentParser
import Lifecycle

final class Commander {
    /// Command to launch a given application.
    private struct Launch: AsyncParsableCommand {
        static var configuration: CommandConfiguration {
            let commander = Container.require(Commander.self)
            return CommandConfiguration(
                abstract: "Launch your app.",
                subcommands: commander.commands,
                defaultSubcommand: commander.defaultCommand
            )
        }

        /// The environment file to load. Defaults to `env`.
        @Option(name: .shortAndLong) var env: String = "env"

        /// The environment file to load. Defaults to `env`.
        @Option(name: .shortAndLong) var log: Logger.Level? = nil
    }

    private var commands: [Command.Type] = []
    private var defaultCommand: Command.Type = ServeCommand.self

    // MARK: Registering Commands

    func register(command: (some Command).Type) {
        commands.append(command)
    }

    func setDefault(command: (some Command).Type) {
        defaultCommand = command
    }

    // MARK: Running Commands

    /// Runs a command based on the given arguments. Returns the command that
    /// ran, after it is finished running.
    func runCommand(args: [String]? = nil) async throws -> ParsableCommand {
        
        // 0. Parse the Command

        // When running a command with no arguments during a test, send an empty
        // array of arguments to swift-argument-parser. Otherwise, it will
        // try to parse the arguments of the test runner throw errors.
        var command = try Launch.parseAsRoot(args ?? (Env.isTesting ? [] : nil))

        // 1. Run the Command on an `EventLoop`.

        try await Loop.asyncSubmit {
            guard var asyncCommand = command as? AsyncParsableCommand else {
                try command.run()
                return
            }

            try await asyncCommand.run()
        }
        .get()

        return command
    }

    func exit(error: Error) {
        Launch.exit(withError: error)
    }
}

extension Logger.Level: ExpressibleByArgument {}
