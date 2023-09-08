struct SchedulingPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.register(Scheduler()).singleton()
    }

    func shutdownServices(in app: Application) async throws {
        try await app.container.resolve(Scheduler.self)?.shutdown()
    }
}
