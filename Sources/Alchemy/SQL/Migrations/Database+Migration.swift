import Foundation
import NIO

extension Database {
    /// Represents a table for storing migration data. Alchemy will use
    /// this table for keeping track of the various batches of
    /// migrations that have been run.
    private struct AppliedMigration: Model {
        /// A migration for adding the `AlchemyMigration` table.
        struct Migration: Alchemy.Migration {
            func up(db: Database) async throws {
                try await db.create(table: table, ifNotExists: true) {
                    $0.increments("id").primary()
                    $0.string("name").notNull()
                    $0.int("batch").notNull()
                    $0.date("run_at").notNull()
                }
            }

            func down(db: Database) async throws {
                try await db.drop(table: table)
            }
        }

        static let table = "migrations"

        /// Serial primary key.
        var id: PK<Int> = .new

        /// The name of the migration.
        let name: String

        /// The batch this migration was run as a part of.
        let batch: Int

        /// The timestamp when this migration was run.
        let runAt: Date?
    }

    /// Applies all outstanding migrations to the database in a single
    /// batch. Migrations are read from `database.migrations`.
    public func migrate() async throws {
        let applied = try await getAppliedMigrations().map(\.name)
        let toApply = migrations.filter { !applied.contains($0.name) }
        try await migrate(toApply)
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

    /// Run the `.up` functions of an array of migrations in order.
    ///
    /// - Parameters:
    ///   - migrations: The migrations to apply to this database.
    public func migrate(_ migrations: [Migration]) async throws {
        guard !migrations.isEmpty else {
            Log.info("Nothing to migrate.".green)
            return
        }

        let lastBatch = try await getLastBatch()
        for m in migrations {
            let start = Date()
            Log.info("Migrating: ".yellow + m.name)
            try await m.up(db: self)
            try await AppliedMigration(name: m.name, batch: lastBatch + 1, runAt: Date()).insert(db: self)
            Log.info("Migrated: ".green + m.name + " (\(start.elapsedString))")
        }
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

        for m in migrations {
            let start = Date()
            Log.info("Rollbacking: ".yellow + m.name)
            try await m.down(db: self)
            try await AppliedMigration.delete("name" == m.name)
            Log.info("Rollbacked: ".green + m.name + " (\(start.elapsedString))")
        }
    }

    private func getLastBatch() async throws -> Int {
        let row = try await table(AppliedMigration.table).select(["MAX(batch)"]).first
        guard let value = row?.fields.first?.value else {
            return 0
        }

        return try value.isNull() ? 0 : value.int()
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
        return try await query.all()
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

extension Date {
    fileprivate var elapsedString: String {
        let elapsedms = Date().timeIntervalSince(self) * 1_000
        let string = "\(elapsedms)"
        let components = string.components(separatedBy: ".")
        let whole = components[0]
        let fraction = components[safe: 1].map { $0.prefix(2) } ?? ""
        return "\(whole).\(fraction)ms"
    }
}
