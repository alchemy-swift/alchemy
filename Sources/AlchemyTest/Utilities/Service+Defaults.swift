public var Http: Client {
    Container.resolve(Client.self)
}

public var DB: Database {
    Container.resolve(Database.self)
}
