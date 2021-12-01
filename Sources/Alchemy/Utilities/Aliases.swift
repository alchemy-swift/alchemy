// The default configured Client
public var Http: Client {
    .resolve(.default)
}

// The default configured Database
public var DB: Database {
    .resolve(.default)
}

// The default configured Storage
public var Store: Storage {
    .resolve(.default)
}
