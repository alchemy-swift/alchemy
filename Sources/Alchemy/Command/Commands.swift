struct Commands: Plugin {
    func registerServices(in app: Application) {
        app.container.registerSingleton(Commander())
        if app.container.env.isTest {
            FileCreator.mock()
        }
    }

    func boot(app: Application) {
        for command in app.configuration.commands {
            app.registerCommand(command)
        }

        app.registerCommand(ControllerMakeCommand.self)
        app.registerCommand(MiddlewareMakeCommand.self)
        app.registerCommand(MigrationMakeCommand.self)
        app.registerCommand(ModelMakeCommand.self)
        app.registerCommand(JobMakeCommand.self)
        app.registerCommand(ViewMakeCommand.self)
        app.registerCommand(ServeCommand.self)

        app.setDefaultCommand(ServeCommand.self)
    }
}

extension Application {
    fileprivate var commander: Commander {
        container.resolveAssert()
    }

    public func registerCommand(_ command: (some Command).Type) {
        commander.register(command: command)
    }

    public func setDefaultCommand(_ command: (some Command).Type) {
        commander.defaultCommand = command
    }

    /// Starts the application with the given arguments.
    public func start(_ args: String...) async throws {
        try await start(args: args.isEmpty ? nil : args)
    }

    public func start(args: [String]? = nil) async throws {
        try await commander.start(args: args)
    }

    /// Stops your application from running.
    public func stop() async throws {
        try await Lifecycle.shutdown()
    }
}
