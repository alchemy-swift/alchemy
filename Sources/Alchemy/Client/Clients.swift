struct HTTPClients: Plugin {
    func registerServices(in app: Application) {
        app.container.register(Client())
    }
}
