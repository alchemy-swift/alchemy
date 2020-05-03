public enum PostgreSQL { }

public final class PostgresDatabase: Database {
    public typealias Kind = PostgreSQL
    public var pool: ConnectionPool?
}

extension PostgresDatabase: Injectable {
    public static func create(identifier: String?, _ isMock: Bool) -> PostgresDatabase {
        struct Storage {
            static var singleton: PostgresDatabase?
            static var dict: [String: PostgresDatabase] = [:]
        }
        
        if let identifier = identifier, let database = Storage.dict[identifier] {
            return database
        } else if let identifier = identifier {
            let newDB = PostgresDatabase()
            Storage.dict[identifier] = newDB
            return newDB
        } else if let singleton = Storage.singleton {
            return singleton
        } else {
            let singleton = PostgresDatabase()
            Storage.singleton = singleton
            return singleton
        }
    }
}
