import Foundation

extension Database {
    /// Represents a table for storing migration data. Alchemy will use
    /// this table for keeping track of the various batches of
    /// migrations that have been run.
    @Model
    struct AppliedMigration {
        /// A migration for adding the `AlchemyMigration` table.
        struct Migration: Alchemy.Migration {
            func up(db: Database) async throws {
                try await db.createTable(table, ifNotExists: true) {
                    $0.increments("id").primary()
                    $0.string("name").notNull()
                    $0.int("batch").notNull()
                    $0.date("run_at").notNull()
                }
            }

            func down(db: Database) async throws {
                try await db.dropTable(table)
            }
        }

        static let table = "migrations"

        /// Serial primary key.
        var id: Int

        /// The name of the migration.
        let name: String

        /// The batch this migration was run as a part of.
        let batch: Int

        /// The timestamp when this migration was run.
        let runAt: Date?
    }

    /// Applies the provided migrations or all outstanding migrations to the
    /// database in a single batch. Migrations are read from
    /// `database.migrations`.
    public func migrate(_ migrations: [Migration]? = nil) async throws {
        let appliedMigrations = try await getAppliedMigrations().map(\.name)
        let migrations = (migrations ?? self.migrations).filter { !appliedMigrations.contains($0.name) }

        guard !migrations.isEmpty else {
            Log.info("Nothing to migrate.".green)
            return
        }

        Log.info("Running migrations.")
        let lastBatch = try await getLastBatch()
        for m in migrations {
            let start = Date()
            try await m.up(db: self)
            try await AppliedMigration(name: m.name, batch: lastBatch + 1, runAt: Date()).insert(on: self)
            commentMigrationDone(m, startedAt: start)
        }
    }

    /// Rolls back all migrations from all batches.
    public func reset() async throws {
        try await rollback(getAppliedMigrations().reversed())
    }

    /// Rolls back the latest migration batch.
    public func rollback() async throws {
        let lastBatch = try await getLastBatch()
        let migrations = try await getAppliedMigrations(batch: lastBatch, enforceRegistration: true)
        try await rollback(migrations.reversed())
    }

    /// Run the `.down` functions of an array of migrations, in order.
    ///
    /// - Parameter migrations: The migrations to rollback on this
    ///   database.
    public func rollback(_ migrations: [Migration]) async throws {
        guard !migrations.isEmpty else {
            Log.info("Nothing to rollback.".green)
            return
        }

        Log.info("Rolling back migrations.")
        for m in migrations {
            let start = Date()
            try await m.down(db: self)
            try await AppliedMigration.delete("name" == m.name)
            commentMigrationDone(m, startedAt: start)
        }
    }

    private func getLastBatch() async throws -> Int {
        guard try await hasTable(AppliedMigration.table) else {
            return 0
        }

        return try await table(AppliedMigration.table)
            .select("MAX(batch)")
            .first()?
            .decode(Int?.self) ?? 0
    }

    private func commentMigrationDone(_ migration: Migration, startedAt: Date) {
        let time = startedAt.elapsedString
        let done = "DONE"
        let left = "\(migration.name)"
        let dots = Log.dots(left: left, right: "\(time) \(done)")
        Log.comment("\(left.white) \(dots.lightBlack) \(time.lightBlack) \(done.green)")
    }

    /// Gets any existing migrations in the order that they were applied. This
    /// will create the migration table if it doesn't already exist.
    /// 
    /// - Parameters:
    ///   - batch: An optional batch to get the specific migrations of.
    ///   - enforceRegistration: If true, this function will throw if a
    ///     migration in your database isn't registered with the app.
    /// - Returns: The migrations that are applied to this database.
    public func getAppliedMigrations(batch: Int? = nil, enforceRegistration: Bool = false) async throws -> [Migration] {
        if try await !hasTable(AppliedMigration.table) {
            try await AppliedMigration.Migration().up(db: self)
            Log.info("Migration table created successfully.".green)
        }

        var query = table(AppliedMigration.self).orderBy("id")
        if let batch {
            query = query.where("batch" == batch)
        }

        let registeredByName = migrations.keyed(by: \.name)
        return try await query.get()
            .compactMap { applied in
                guard let migration = registeredByName[applied.name] else {
                    if enforceRegistration {
                        throw DatabaseError("The latest migration batch contained `\(applied.name)` but there was no matching `Migration` type registered to your Database.")
                    } else {
                        return nil
                    }
                }

                return migration
            }
    }
}
