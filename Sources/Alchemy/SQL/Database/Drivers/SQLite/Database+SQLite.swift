extension Database {
    /// A file based SQLite database configuration.
    ///
    /// - Parameter path: The path of the SQLite database file.
    /// - Returns: The configuration for connecting to this database.
    public static func sqlite(path: String) -> Database {
        Database(provider: SQLiteDatabase(config: .file(path)))
    }
    
    /// An in memory SQLite database configuration with the given identifier.
    public static func sqlite(identifier: String) -> Database {
        Database(provider: SQLiteDatabase(config: .memory(identifier: identifier)))
    }
    
    /// An in memory SQLite database configuration.
    public static var sqlite: Database {
        .memory
    }
    
    /// An in memory SQLite database configuration.
    public static var memory: Database {
        Database(provider: SQLiteDatabase(config: .memory))
    }
}
