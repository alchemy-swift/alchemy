import Alchemy
import NIO

extension PostgresDatabase: SingletonService {
    public static func singleton(in container: Container) throws -> PostgresDatabase {
        let group = try container.resolve(MultiThreadedEventLoopGroup.self)
        return PostgresDatabase(config: .postgres, eventLoopGroup: group)
    }
}

private extension DatabaseConfig {
    static let postgres = DatabaseConfig(
        socket: .ipAddress(host: "127.0.0.1", port: 5432),
        database: "alchemy",
        username: "josh",
        password: "password"
    )
}
