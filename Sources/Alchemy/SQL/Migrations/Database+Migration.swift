import Foundation
import NIO

extension Database {
    /// Applies all outstanding migrations to the database in a single
    /// batch. Migrations are read from `database.migrations`.
    public func migrate() async throws {
        let alreadyMigrated = try await getMigrations()
        
        let currentBatch = alreadyMigrated.map(\.batch).max() ?? 0
        let migrationsToRun = migrations.filter { pendingMigration in
            !alreadyMigrated.contains(where: { $0.name == pendingMigration.name })
        }
        
        if migrationsToRun.isEmpty {
            Log.info("[Migration] no new migrations to apply.")
        } else {
            Log.info("[Migration] applying \(migrationsToRun.count) migrations.")
        }
        
        try await upMigrations(migrationsToRun, batch: currentBatch + 1)
    }
    
    /// Rolls back the latest migration batch.
    public func rollbackMigrations() async throws {
        let alreadyMigrated = try await getMigrations()
        guard let latestBatch = alreadyMigrated.map({ $0.batch }).max() else {
            return
        }
        
        let namesToRollback = alreadyMigrated.filter { $0.batch == latestBatch }.map(\.name)
        let migrationsToRollback = migrations.filter { namesToRollback.contains($0.name) }
        
        if migrationsToRollback.isEmpty {
            Log.info("[Migration] no migrations roll back.")
        } else {
            Log.info("[Migration] rolling back the \(migrationsToRollback.count) migrations from the last batch.")
        }
        
        try await downMigrations(migrationsToRollback)
    }
    
    /// Gets any existing migrations. Creates the migration table if
    /// it doesn't already exist.
    ///
    /// - Returns: The migrations that are applied to this database.
    private func getMigrations() async throws -> [AlchemyMigration] {
        let count: Int
        if driver is PostgresDatabase || driver is MySQLDatabase {
            count = try await table("information_schema.tables").where("table_name" == AlchemyMigration.tableName).count()
        } else {
            count = try await table("sqlite_master")
                .where("type" == "table")
                .where(Query.Where(type: .value(key: "name", op: .notLike, value: .string("sqlite_%"))))
                .count()
        }
        
        if count == 0 {
            Log.info("[Migration] creating '\(AlchemyMigration.tableName)' table.")
            let statements = AlchemyMigration.Migration().upStatements(for: driver.grammar)
            try await runStatements(statements: statements)
        }
        
        return try await AlchemyMigration.query(database: self).allModels()
    }
    
    /// Run the `.down` functions of an array of migrations, in order.
    ///
    /// - Parameter migrations: The migrations to rollback on this
    ///   database.
    private func downMigrations(_ migrations: [Migration]) async throws {
        for m in migrations.sorted(by: { $0.name > $1.name }) {
            let statements = m.downStatements(for: driver.grammar)
            try await runStatements(statements: statements)
            try await AlchemyMigration.query(database: self).where("name" == m.name).delete()
        }
    }
    
    /// Run the `.up` functions of an array of migrations in order.
    ///
    /// - Parameters:
    ///   - migrations: The migrations to apply to this database.
    ///   - batch: The migration batch of these migrations. Based on
    ///     any existing batches that have been applied on the
    ///     database.
    private func upMigrations(_ migrations: [Migration], batch: Int) async throws {
        for m in migrations {
            let statements = m.upStatements(for: driver.grammar)
            try await runStatements(statements: statements)
            _ = try await AlchemyMigration(name: m.name, batch: batch, runAt: Date()).save(db: self)
        }
    }
    
    /// Consecutively run a list of SQL statements on this database.
    ///
    /// - Parameter statements: The statements to consecutively run.
    private func runStatements(statements: [SQL]) async throws {
        for statement in statements {
            _ = try await rawQuery(statement.statement, values: statement.bindings)
        }
    }
}
