var CMD: Commander {
    Container.commander
}

extension Container {
    @Service(.singleton) var commander = Commander()
}
