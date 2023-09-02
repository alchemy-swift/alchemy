struct CommandsPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.register(Commander()).singleton()
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
    var commander: Commander {
        container.require()
    }

    public func registerCommand(_ command: (some Command).Type) {
        commander.register(command: command)
    }

    public func setDefaultCommand(_ command: (some Command).Type) {
        commander.setDefault(command: command)
    }
}
