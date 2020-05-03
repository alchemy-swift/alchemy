import Alchemy

extension DatabaseConfig {
    static let main = DatabaseConfig(
        socket: .ipAddress(host: "127.0.0.1", port: 5432),
        database: "alchemy",
        username: "josh",
        password: "password"
    )
    
    static let someOtherDB = DatabaseConfig(
        socket: .ipAddress(host: "127.0.0.1", port: 5432),
        database: "other",
        username: "josh",
        password: "password"
    )
}
