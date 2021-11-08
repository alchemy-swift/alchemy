import NIO
import RediStack

extension Redis {
    /// Mock Redis with a driver for stubbing specific commands.
    ///
    /// - Parameter name: The name of the redis client to stub,
    ///   defaults to nil for stubbing the default client.
    public static func stub(_ name: String? = nil) -> StubRedis {
        let driver = StubRedis()
        if let name = name {
            config(name, Redis(driver: driver))
        } else {
            config(default: Redis(driver: driver))
        }

        return driver
    }
}
