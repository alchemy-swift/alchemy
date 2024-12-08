/// The default configured Filesystem
public var Storage: Filesystem {
    Container.main.require(default: .local(root: "storage"))
}

public func Storage(_ key: KeyPath<Container, Filesystem>) -> Filesystem {
    Container.main[keyPath: key]
}

extension Application {
    public func setDefaultFilesystem(_ key: KeyPath<Container, Filesystem>) {
        Container.main.setAlias(key)
    }
}
