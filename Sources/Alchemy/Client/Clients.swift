struct Clients: Plugin {
    func registerServices(in container: Container) {
        container.register(Client())
    }
}
