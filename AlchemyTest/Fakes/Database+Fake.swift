extension Database {
    /// Fake this database with an in memory SQLite database.
    ///
    /// - Parameters:
    ///   - seeds: Any migrations to set on the database, they will be run
    ///     before this function returns.
    ///   - seeders: Any seeders to set on the database, they will be run before
    ///     this function returns.
    public func fake(keyMapping: KeyMapping = .snakeCase, migrations: [Migration] = [], seeders: [Seeder] = []) async throws {
        self.provider = SQLiteDatabaseProvider(configuration: .init(storage: .memory(identifier: UUID().uuidString)))
        self.keyMapping = keyMapping
        self.migrations = migrations
        self.seeders = seeders
        if !migrations.isEmpty { try await migrate() }
        if !seeders.isEmpty { try await seed() }
    }
}
