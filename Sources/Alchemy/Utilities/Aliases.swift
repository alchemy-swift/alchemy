// The default configured Client
public var Http: Client {
    Container.resolve(Client.self)
}

// The default configured Database
public var DB: Database {
    Container.resolve(Database.self)
}
