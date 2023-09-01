extension RedisClient {
    /// Mock Redis with a provider for stubbing specific commands.
    ///
    /// - Parameter id: The id of the redis client to stub.
    public static func stub(_ id: Identifier? = nil) -> StubRedis {
        let provider = StubRedis()
        Container.register(RedisClient(provider: provider), id: id).singleton()
        return provider
    }
}
