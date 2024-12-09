import Alchemy
import RediStack

extension Alchemy.RedisClient {
    /// Used for running integration tests.
    static var integration: Alchemy.RedisClient {
        .configuration(RedisConnectionPool.Configuration(
            initialServerConnectionAddresses: [
                try! .makeAddressResolvingHost("localhost", port: 6379)
            ],
            maximumConnectionCount: .maximumActiveConnections(1),
            connectionFactoryConfiguration: RedisConnectionPool.ConnectionFactoryConfiguration(connectionDefaultLogger: Log),
            connectionRetryTimeout: .milliseconds(100)
        ))
    }
    
    func checkAvailable() async -> Bool {
        (try? await ping().get()) != nil
    }
}
