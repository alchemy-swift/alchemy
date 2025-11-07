/// The application Logger
public var Log: Logger {
    Container.main.require(default: .default)
}

public func Log(_ key: KeyPath<Container, Logger>) -> Logger {
    Container.main[keyPath: key]
}

public func Log(_ keys: KeyPath<Container, Logger>...) -> Logger {
    Logger(loggers: keys.map(Log))
}

extension Container {
    /// The default logger, only used if a user doesn't set a default logger.
    @Service(.singleton) public var alchemy: Logger = .default
}

extension Application {
    public func setDefaultLogger(_ key: KeyPath<Container, Logger>) {
        Container.main.setAlias(key)
    }
}
