import NIO
import RediStack

extension Redis {
    /// Mock Redis with a driver for stubbing specific commands.
    ///
    /// - Parameter id: The id of the redis client to stub, defaults to
    ///   `default`.
    public static func stub(_ id: Identifier = .default) -> StubRedis {
        let driver = StubRedis()
        register(id, Redis(driver: driver))
        return driver
    }
}
