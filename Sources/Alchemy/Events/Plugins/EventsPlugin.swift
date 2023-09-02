struct EventsPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.register(EventBus()).singleton()
    }
}
