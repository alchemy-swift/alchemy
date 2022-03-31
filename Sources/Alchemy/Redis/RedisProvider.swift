import RediStack

/// Under the hood provider for `Redis`. Used so either connection pools
/// or connections can be injected into `Redis` for accessing redis.
public protocol RedisProvider {
    /// Get a redis client for running commands.
    func getClient() throws -> RediStack.RedisClient
    
    /// Log with the given logger.
    func logging(to logger: Logger) -> RediStack.RedisClient
    
    /// Shut down.
    func shutdown() throws
    
    /// Runs a transaction on the redis client using a given closure.
    ///
    /// - Parameter transaction: An asynchronous transaction to run on
    ///   the connection.
    /// - Returns: The resulting value of the transaction.
    func transaction<T>(_ transaction: @escaping (RedisProvider) async throws -> T) async throws -> T
}
