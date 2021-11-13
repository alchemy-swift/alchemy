extension Database {
    /// Fake the database with an in memory SQLite database.
    ///
    ////// - Parameter name:
    ///
    /// - Parameters:
    ///   - id: The identifier of the database to fake, defaults to `default`.
    ///   - migrate: Whether migrations should be synchronously run
    ///     before returning from this function. Defaults to `true`.
    ///   - seed: Whether the database should be synchronously seeded
    ///     before returning from this function. Defaults to `false`.
    public static func fake(_ id: Identifier = .default, migrations: [Migration] = [], seeders: [Seeder] = []) {
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
    }
}
