struct Schedules: Plugin {
    func registerServices(in app: Application) {
        app.container.register(Scheduler()).singleton()
    }

    func boot(app: Application) async throws {
        app.schedule(on: Schedule)
        app.registerCommand(ScheduleCommand.self)
    }

    func shutdownServices(in app: Application) async throws {
        try await app.container.resolve(Scheduler.self)?.shutdown()
    }
}
