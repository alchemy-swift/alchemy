extension RedisClient {
    /// Mock this client with a provider for stubbing specific commands.
    public func stub() -> StubRedis {
        let stub = StubRedis()
        self.provider = stub
        return stub
    }
}
