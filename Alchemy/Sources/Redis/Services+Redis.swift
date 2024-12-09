/// The default Redis client
public var Redis: RedisClient {
    Container.main.require()
}

public func Redis(_ key: KeyPath<Container, RedisClient>) -> RedisClient {
    Container.main[keyPath: key]
}

extension Application {
    public func setDefaultRedis(_ key: KeyPath<Container, RedisClient>) {
        Container.main.setAlias(key)
    }
}
