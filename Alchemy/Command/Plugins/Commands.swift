public struct Commands: Plugin, ExpressibleByArrayLiteral {
    private let commands: [Command.Type]
    
    public init(arrayLiteral elements: Command.Type...) {
        self.commands = elements
    }
    
    public func boot(app: Application) {
        app.container.register(Commander()).singleton()

        for command in commands {
            app.registerCommand(command)
        }
        
        app.registerCommand(ControllerMakeCommand.self)
        app.registerCommand(MiddlewareMakeCommand.self)
        app.registerCommand(MigrationMakeCommand.self)
        app.registerCommand(ModelMakeCommand.self)
        app.registerCommand(JobMakeCommand.self)
        app.registerCommand(ViewMakeCommand.self)
        app.registerCommand(ServeCommand.self)
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
