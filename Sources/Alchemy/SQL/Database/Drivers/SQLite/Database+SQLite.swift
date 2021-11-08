extension Database {
    /// A file based SQLite database configuration.
    ///
    /// - Parameter path: The path of the SQLite database file.
    /// - Returns: The configuration for connecting to this database.
    public static func sqlite(path: String) -> Database {
        Database(driver: SQLiteDatabase(config: .file(path)))
    }
    
    /// An in memory SQLite database configuration.
    public static var sqlite: Database {
        Database(driver: SQLiteDatabase(config: .memory))
    }
    
    /// An in memory SQLite database configuration.
    public static var memory: Database {
        sqlite
    }
}
