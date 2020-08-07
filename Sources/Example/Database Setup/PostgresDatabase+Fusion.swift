import Alchemy
import NIO

extension PostgresDatabase: SingletonService {
    public static func singleton(in container: Container) throws -> PostgresDatabase {
        let group = try container.resolve(MultiThreadedEventLoopGroup.self)
        return PostgresDatabase(config: .postgres, eventLoopGroup: group)
    }
}

private extension PostgresConfig {
    static let postgres = PostgresConfig(
        socket: .ipAddress(
            host: Env.DB_HOST!,
            port: Env.DB_PORT!
        ),
        database: Env.DB_DATABASE!,
        username: Env.DB_USER!,
        password: Env.DB_PASS!
    )
}
