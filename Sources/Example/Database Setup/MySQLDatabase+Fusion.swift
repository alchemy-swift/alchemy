import Alchemy
import NIO

extension MySQLDatabase: SingletonService {
    public static func singleton(in container: Container) throws -> MySQLDatabase {
        MySQLDatabase(config: .mysql)
    }
}

private extension DatabaseConfig {
    static let mysql = DatabaseConfig(
        socket: .ip(host: "127.0.0.1", port: 32773),
        database: "alchemy",
        username: "root",
        password: "hallow"
    )
}
