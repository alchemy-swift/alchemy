import Alchemy
import NIO

extension PostgresDatabase: SingletonService {
    public static func singleton(in container: Container) throws -> PostgresDatabase {
        PostgresDatabase(config: .postgres)
    }
}

private extension DatabaseConfig {
    static let postgres = DatabaseConfig(
        socket: .ip(
            host: Env.DB_HOST!,
            port: Env.DB_PORT!
        ),
        database: Env.DB_DATABASE!,
        username: Env.DB_USER!,
        password: Env.DB_PASS!
    )
}
