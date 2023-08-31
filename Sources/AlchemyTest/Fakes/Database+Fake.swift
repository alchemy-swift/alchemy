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
    public static func fake(_ id: Identifier? = nil, migrations: [Migration] = [], seeders: [Seeder] = []) async throws -> Database {
        let db = Database.sqlite
        Container.register(db, id: id).singleton()
        Container
            .require(ServiceLifecycle.self)
            .registerShutdown(label: "fake db", .async {
                try await db.shutdown()
            })
        db.migrations = migrations
        db.seeders = seeders
        if !migrations.isEmpty { try await db.migrate() }
        if !seeders.isEmpty { try await db.seed() }
        return db
    }
}
