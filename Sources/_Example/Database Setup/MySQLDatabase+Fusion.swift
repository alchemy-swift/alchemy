import Alchemy
import NIO

extension MySQLDatabase: SingletonService {
    public static func singleton(in container: Container) throws -> MySQLDatabase {
        let group = try container.resolve(MultiThreadedEventLoopGroup.self)
        return MySQLDatabase(config: .mysql, eventLoopGroup: group)
    }
}

private extension MySQLConfig {
    static let mysql = MySQLConfig(
        socket: .ipAddress(host: "127.0.0.1", port: 32773),
        database: "alchemy",
        username: "root",
        password: "hallow"
    )
}
