struct RoutingPlugin: Plugin {
    func registerServices(in container: Container) {
        container.registerSingleton(Router())
    }
}
