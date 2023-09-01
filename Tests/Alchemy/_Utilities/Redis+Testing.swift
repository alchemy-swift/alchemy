import Alchemy
import RediStack

extension Alchemy.RedisClient {
    static var testing: Alchemy.RedisClient {
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
        do {
            _ = try await ping().get()
            return true
        } catch {
            return false
        }
    }
}
