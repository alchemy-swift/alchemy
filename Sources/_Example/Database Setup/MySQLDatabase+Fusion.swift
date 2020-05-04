import Alchemy
import NIO

extension MySQLDatabase: IdentifiedService {
    public enum Configuration {
        case one
        case two
        
        var config: DatabaseConfig {
            switch self {
            case .one:
                return .mySQL2
            case .two:
                return .mySQL2
            }
        }
    }
    
    public static func singleton(in container: Container, for identifier: Configuration) throws -> MySQLDatabase {
        let group: MultiThreadedEventLoopGroup = try container.resolve()
        return MySQLDatabase(config: identifier.config, eventLoopGroup: group)
    }
}

private extension DatabaseConfig {
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
