/// All boot & shutdown logic related to various Alchemy services
struct Core: Plugin {
    func boot(app: Application) async throws {
        // register all of Alchemy's built in commands

        CMD.register(ServeCommand.self) // serving
        CMD.register(ScheduleCommand.self) // scheduling
        CMD.register(ControllerMakeCommand.self) // makes
        CMD.register(MiddlewareMakeCommand.self)
        CMD.register(MigrationMakeCommand.self)
        CMD.register(ModelMakeCommand.self)
        CMD.register(JobMakeCommand.self)
        CMD.register(ViewMakeCommand.self)
        CMD.register(SeedCommand.self) // seeding
        CMD.register(MigrateCommand.self) // migrations
        CMD.register(RollbackMigrationsCommand.self)
        CMD.register(ResetMigrationsCommand.self)
        CMD.register(RefreshMigrationsCommand.self)
        CMD.register(WorkCommand.self) // queues

        // register any custom commands

        for command in app.commands {
            CMD.register(command)
        }

        // register any generated routes defined on the application

        if let controller = app as? Controller {
            controller.route(app)
        }
    }

    func shutdown(app: Application) async throws {
        try _Http.shutdown()
        try await LoopGroup.shutdownGracefully()
        Jobs.reset()
    }
}
