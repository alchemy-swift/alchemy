struct EventStreams: Plugin {
    func boot(app: Application) {
        app.container.register(EventBus()).singleton()
    }
}
