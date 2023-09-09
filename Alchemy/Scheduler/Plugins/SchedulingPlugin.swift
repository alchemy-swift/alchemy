struct SchedulingPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.register(Scheduler()).singleton()
    }

    func boot(app: Application) async throws {
        app.registerCommand(ScheduleCommand.self)
    }

    func shutdownServices(in app: Application) async throws {
        try await app.container.resolve(Scheduler.self)?.shutdown()
    }
}
