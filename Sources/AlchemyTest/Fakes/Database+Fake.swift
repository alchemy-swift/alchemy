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
    public static func fake(_ name: String? = nil, migrate: Bool = true, seed: Bool = false) {
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
                if migrate { try await db.migrate() }
                if seed { try await db.seed() }
            } catch {
                Log.error("Error initializing fake database: \(error)")
            }
            
            sem.signal()
        }
        
        sem.wait()
    }
}
