extension Database {
    /// Fake the database with an in memory SQLite database.
    ///
    ////// - Parameter name:
    ///
    /// - Parameters:
    ///   - id: The identifier of the database to fake, defaults to `default`.
    ///   - seeds: Any migrations to set on the database, they will be run
    ///     before this function returns.
    ///   - seeders: Any seeders to set on the database, they will be run before
    ///     this function returns.
    @discardableResult
    public static func fake(_ id: Identifier = .default, migrations: [Migration] = [], seeders: [Seeder] = []) -> Database {
        let db = Database.sqlite
        db.migrations = migrations
        db.seeders = seeders
        register(id, db)
        
        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                if !migrations.isEmpty { try await db.migrate() }
                if !seeders.isEmpty { try await db.seed() }
            } catch {
                Log.error("Error initializing fake database: \(error)")
            }
            
            sem.signal()
        }
        
        sem.wait()
        return db
    }
}
