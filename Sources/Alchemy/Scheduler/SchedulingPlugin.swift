struct SchedulingPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.registerSingleton(Scheduler())
    }

    func shutdownServices(in app: Application) async throws {
        try await app.container.resolve(Scheduler.self)?.shutdown()
    }
}
