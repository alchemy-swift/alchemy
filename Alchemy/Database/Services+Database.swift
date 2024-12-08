/// The default configured Database
public var DB: Database {
    Container.main.require()
}

public func DB(_ key: KeyPath<Container, Database>) -> Database {
    Container.main[keyPath: key]
}

extension Application {
    public func setDefaultDatabase(_ key: KeyPath<Container, Database>) {
        Container.main.setAlias(key)
    }
}
