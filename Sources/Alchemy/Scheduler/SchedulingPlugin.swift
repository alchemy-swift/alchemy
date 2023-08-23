struct SchedulingPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.registerSingleton(Scheduler())
    }
}
