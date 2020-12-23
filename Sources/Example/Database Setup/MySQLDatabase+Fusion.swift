import Alchemy
import NIO

extension DatabaseConfig {
    static let mysql = DatabaseConfig(
        socket: .ip(host: "127.0.0.1", port: 32773),
        database: "alchemy",
        username: "root",
        password: "hallow"
    )
    
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
