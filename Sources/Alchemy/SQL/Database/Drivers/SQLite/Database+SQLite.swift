extension Database {
    /// An in memory SQLite database configuration.
    public static var memory: Database {
        sqlite(identifier: UUID().uuidString)
    }

    /// An in memory SQLite database configuration.
    public static var sqlite: Database {
        .memory
    }

    /// A file based SQLite database configuration.
    ///
    /// - Parameter path: The path of the SQLite database file.
    /// - Returns: The configuration for connecting to this database.
    public static func sqlite(path: String) -> Database {
        sqlite(configuration: .init(storage: .file(path: path), enableForeignKeys: true))
    }
    
    /// An in memory SQLite database configuration with the given identifier.
    public static func sqlite(identifier: String) -> Database {
        sqlite(configuration: .init(storage: .memory(identifier: identifier), enableForeignKeys: true))
    }

    public static func sqlite(configuration: SQLiteConfiguration) -> Database {
        Database(provider: SQLiteDatabaseProvider(configuration: configuration), grammar: SQLiteGrammar())
    }
}
