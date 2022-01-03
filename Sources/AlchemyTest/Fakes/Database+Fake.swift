extension Database {
    /// Fake the database with an in memory SQLite database.
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
        bind(id, db)
        
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
    
    /// Synchronously migrates the database, useful for setting up the database
    /// before test cases.
    public func syncMigrate() {
        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                if !migrations.isEmpty { try await migrate() }
            } catch {
                Log.error("Error migrating test database: \(error)")
            }
            
            sem.signal()
        }
        
        sem.wait()
    }
    
    /// Synchronously seeds the database, useful for setting up the database
    /// before test cases.
    public func syncSeed() {
        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                if !seeders.isEmpty { try await seed() }
            } catch {
                Log.error("Error seeding test database: \(error)")
            }
            
            sem.signal()
        }
        
        sem.wait()
    }
}
