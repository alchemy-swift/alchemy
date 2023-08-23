struct RoutingPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.registerSingleton(Router())
    }
}
