var CMD: Commander {
    Container.$commander
}

extension Container {
    @Singleton var commander = Commander()
}
