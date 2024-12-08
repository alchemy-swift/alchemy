/// Your app's default Cache.
public var Stash: Cache {
    Container.main.require(default: .memory)
}

public func Stash(_ key: KeyPath<Container, Cache>) -> Cache {
    Container.main[keyPath: key]
}

extension Application {
    public func setDefaultCache(_ key: KeyPath<Container, Cache>) {
        Container.main.setAlias(key)
    }
}
