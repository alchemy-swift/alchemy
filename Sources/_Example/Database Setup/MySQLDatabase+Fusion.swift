import Alchemy
import NIO

extension MySQLDatabase: IdentifiedService {
    public enum Configuration {
        case one
        case two
    }
    
    public static func singleton(in container: Container, for identifier: Configuration) throws -> MySQLDatabase {
        switch identifier {
        case .one:
            return MySQLDatabase()
        case .two:
            return MySQLDatabase()
        }
    }
}
