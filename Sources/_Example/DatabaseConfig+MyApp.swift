import Alchemy
import NIO

extension PostgresDatabase: Fusable {
    public static func register(in container: Container) throws {
        let group = try container.resolve(MultiThreadedEventLoopGroup.self)
        try container.register(singleton: PostgresDatabase(config: .postgres, eventLoopGroup: group))
    }
}

extension MySQLDatabase: Fusable {
    public static func register(in container: Container) throws {
        let group = try container.resolve(MultiThreadedEventLoopGroup.self)
        
        let main = MySQLDatabase(config: .mySQL1, eventLoopGroup: group)
        let other = MySQLDatabase(config: .mySQL2, eventLoopGroup: group)
        
        try container.register(singleton: main, identifier: "mySQL1")
        try container.register(singleton: other, identifier: "mySQL2")
    }
}

extension DatabaseConfig {
    static let postgres = DatabaseConfig(
        socket: .ipAddress(host: "127.0.0.1", port: 5432),
        database: "alchemy",
        username: "josh",
        password: "password"
    )
    
    static let mySQL1 = DatabaseConfig(
        socket: .ipAddress(host: "127.0.0.1", port: 3306),
        database: "mysql1",
        username: "josh",
        password: "password"
    )
    
    static let mySQL2 = DatabaseConfig(
        socket: .ipAddress(host: "127.0.0.1", port: 3306),
        database: "mysql2",
        username: "josh",
        password: "password"
    )
}
