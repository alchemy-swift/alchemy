extension Database {
    /// Fake the database with an in memory SQLite database.
    ///
    ////// - Parameter name:
    ///
    /// - Parameters:
    ///   - name: The name of the database to fake, defaults to `nil`
    ///     which fakes the default database.
    ///   - migrate: Whether migrations should be synchronously run
    ///     before returning from this function. Defaults to `true`.
    ///   - seed: Whether the database should be synchronously seeded
    ///     before returning from this function. Defaults to `false`.
    public static func fake(_ name: String? = nil, migrations: [Migration] = [], seeders: [Seeder] = []) {
        let db = Database.sqlite
        db.migrations = migrations
        db.seeders = seeders
        if let name = name {
            config(name, db)
        } else {
            config(default: db)
        }
        
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
    }
}
