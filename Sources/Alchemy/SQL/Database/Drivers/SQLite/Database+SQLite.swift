public extension Database {
    /// A file based SQLite database configuration.
    ///
    /// - Parameter path: The path of the SQLite database file.
    /// - Returns: The configuration for connecting to this database.
    static func sqlite(path: String) -> Database {
        Database(driver: SQLiteDatabase(config: .file(path)))
    }
    
    /// An in memory SQLite database configuration.
    static var sqlite: Database {
        Database(driver: SQLiteDatabase(config: .memory))
    }
}

extension Database {
    /// Fake the database with an in memory SQLite database.
    ///
    /// - Parameter name: The name of the database to fake, defaults
    ///   to nil for faking the default database.
    static func fake(_ name: String? = nil) {
        let db = Database.sqlite
        if let name = name {
            db.migrations = named(name).migrations
            config(name, db)
        } else {
            db.migrations = `default`.migrations
            config(default: db)
        }
        
        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                try await db.migrate()
            } catch {
                Log.error("Error mocking database: \(error)")
            }
            
            sem.signal()
        }
        
        sem.wait()
    }
}

