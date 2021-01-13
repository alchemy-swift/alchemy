import Foundation
import NIO

extension Database {
    /// Applies all outstanding migrations to the database in a single
    /// batch. Migrations are read from `database.migrations`.
    ///
    /// - Returns: A future that completes when all migrations have
    ///   been applied.
    public func migrate() -> EventLoopFuture<Void> {
        // 1. Get all already migrated migrations
        return self.getMigrations()
            // 2. Figure out which database migrations should be
            // migrated
            .map { alreadyMigrated in
                let currentBatch = alreadyMigrated.map(\.batch).max() ?? 0
                let migrationsToRun = self.migrations.filter { pendingMigration in
                    !alreadyMigrated.contains(where: { $0.name == pendingMigration.name })
                }
                
                return (migrationsToRun, currentBatch + 1)
            }
            // 3. Run migrations & record in migration table
            .flatMap(self.upMigrations)
    }
    
    /// Rolls back the latest migration batch.
    ///
    /// - Returns: A future that completes when the rollback is
    ///   complete.
    public func rollbackMigrations() -> EventLoopFuture<Void> {
        self.getMigrations()
            .map { alreadyMigrated -> [Migration] in
                guard let latestBatch = alreadyMigrated.map({ $0.batch }).max() else {
                    return []
                }
                
                let namesToRollback = alreadyMigrated.filter { $0.batch == latestBatch }.map(\.name)
                let migrationsToRollback = self.migrations.filter { namesToRollback.contains($0.name) }
                
                return migrationsToRollback
            }
            .flatMap(self.downMigrations)
    }
    
    /// Gets any existing migrations. Creates the migration table if
    /// it doesn't already exist.
    ///
    /// - Returns: A future containing an array of all the migrations
    ///   that have been applied to this database.
    private func getMigrations() -> EventLoopFuture<[AlchemyMigration]> {
        let createMigrationsTable = AddAlchemyMigration().upStatements(for: self.grammar).first!
        return self.runRawQuery(createMigrationsTable.query)
            .flatMap { _ in
                AlchemyMigration.query(database: self).allModels()
            }
    }
    
    /// Run the `.down` functions of an array of migrations, in order.
    ///
    /// - Parameter migrations: The migrations to rollback on this
    ///   database.
    /// - Returns: A future that completes when the rollback is
    ///   finished.
    private func downMigrations(_ migrations: [Migration]) -> EventLoopFuture<Void> {
        var elf = Services.eventLoop.future()
        for m in migrations.sorted(by: { $0.name > $1.name }) {
            let statements = m.downStatements(for: self.grammar)
            elf = elf.flatMap { self.runStatements(statements: statements) }
                .flatMap {
                    AlchemyMigration.query()
                        .where("name" == m.name)
                        .delete()
                        .voided()
                }
        }
        
        return elf
    }
    
    /// Run the `.up` functions of an array of migrations in order.
    ///
    /// - Parameters:
    ///   - migrations: The migrations to apply to this database.
    ///   - batch: The migration batch of these migrations. Based on
    ///     any existing batches that have been applied on the
    ///     database.
    /// - Returns: A future that completes when the migration is
    ///   applied.
    private func upMigrations(_ migrations: [Migration], batch: Int) -> EventLoopFuture<Void> {
        var elf = Services.eventLoop.future()
        for m in migrations {
            let statements = m.upStatements(for: self.grammar)
            elf = elf.flatMap { self.runStatements(statements: statements) }
                .flatMap {
                    AlchemyMigration(name: m.name, batch: batch, runAt: Date())
                        .save(db: self)
                        .voided()
                }
        }
        
        return elf
    }
    
    /// Consecutively run a list of SQL statements on this database.
    ///
    /// - Parameter statements: The statements to consecutively run.
    /// - Returns: A future that completes when all statements have
    ///   been run.
    private func runStatements(statements: [SQL]) -> EventLoopFuture<Void> {
        var elf = Services.eventLoop.future()
        for statement in statements {
            elf = elf.flatMap { _ in
                self.runRawQuery(statement.query, values: statement.bindings)
                    .voided()
            }
        }
        
        return elf.voided()
    }
}
