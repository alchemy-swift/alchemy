public enum MySQL { }

// Not working at the moment, seems like https://github.com/vapor/mysql-nio has some larger updates coming
// soon.
public final class MySQLDatabase: Database {
    public typealias Kind = MySQL
    public var pool: ConnectionPool?
}

extension MySQLDatabase: Injectable {
    public static func create(identifier: String?, _ isMock: Bool) -> MySQLDatabase {
        struct Storage {
            static let singleton = MySQLDatabase()
        }
        
        return Storage.singleton
    }
}
