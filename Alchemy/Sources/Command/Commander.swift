final class Commander {
    /// Command to launch a given application.
    private struct Launch: AsyncParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(
                abstract: "Launch your app.",
                subcommands: CMD.commands,
                defaultSubcommand: CMD.defaultCommand
            )
        }

        /// The environment file to load. Defaults to `env`.
        @Option(name: .shortAndLong) var env: String = "env"

        /// The default log level.
        @Option(name: .shortAndLong) var log: Logger.Level? = nil
    }

    private var commands: [Command.Type] = []
    private var defaultCommand: Command.Type = ServeCommand.self

    // MARK: Running Commands

    /// Runs a command based on the given arguments. Returns the command that
    /// ran, after it is finished running.
    func run(args: [String]? = nil) async throws {

        // When running a command with no arguments during a test, send an empty
        // array of arguments to swift-argument-parser. Otherwise, it will
        // try to parse the test runner arguments and throw errors.
        let args = args ?? (Env.isTesting ? [] : nil)
        var command = try Launch.parseAsRoot(args)
        if var command = command as? AsyncParsableCommand {
            try await command.run()
        } else {
            try command.run()
        }
    }

    func exit(error: Error) {
        Launch.exit(withError: error)
    }

    // MARK: Registering Commands

    func register(_ command: Command.Type) {
        commands.append(command)
    }

    func setDefault(_ command: (some Command).Type) {
        defaultCommand = command
    }
}

extension Logger.Level: @retroactive ExpressibleByArgument {}
