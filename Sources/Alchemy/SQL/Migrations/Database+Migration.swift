import Foundation
import NIO

let kMigrationTable = "_alchemy_migrations"
let kMigrationTableCreateQuery =
    """
    CREATE TABLE IF NOT EXISTS _alchemy_migrations (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        batch INT NOT NULL,
        run_at TIMESTAMPTZ NOT NULL
    )
    """

struct AlchemyMigration: Model {
    static var tableName: String = kMigrationTable
    
    var id: Int?
    let name: String
    let batch: Int
    let runAt: Date?
}

extension Database {
    /// Applies all outstanding migrations to the database.
    ///
    /// Migrations are read from database.migrations.
    public func migrate() -> EventLoopFuture<Void> {
        // 1. Get all already migrated migrations
        return self.getMigrations()
            // 2. Figure out which database migrations should be migrated
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
    
    /// Rolls back the latest migration operation.
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
    
    /// Gets existing migrations. Creates the migration table if it doesn't already exist.
    private func getMigrations() -> EventLoopFuture<[AlchemyMigration]> {
        self.runRawQuery(kMigrationTableCreateQuery, on: Loop.current)
            .flatMap { _ in
                AlchemyMigration.query(database: self).getAll()
            }
    }
    
    private func downMigrations(_ migrations: [Migration]) -> EventLoopFuture<Void> {
        var elf = Loop.current.future()
        for m in migrations {
            let schema = m.downSchema()
            elf = elf.flatMap { self.runStatements(statements: schema.statements) }
                .flatMap {
                    AlchemyMigration.query()
                        .where("name" == m.name)
                        .delete()
                        .voided()
                }
        }
        
        return elf
    }
    
    private func upMigrations(_ migrations: [Migration], batch: Int) -> EventLoopFuture<Void> {
        var elf = Loop.current.future()
        for m in migrations {
            let schema = m.upSchema()
            elf = elf.flatMap { self.runStatements(statements: schema.statements) }
                .flatMap {
                    AlchemyMigration(name: m.name, batch: batch, runAt: Date())
                        .save(db: self)
                        .voided()
                }
        }
        
        return elf
    }
    
    private func runStatements(statements: [SQL]) -> EventLoopFuture<Void> {
        var elf = Loop.current.future()
        for statement in statements {
            elf = elf.flatMap { _ in
                self.runQuery(statement.query, values: statement.bindings, on: Loop.current)
                    .voided()
            }
        }
        
        return elf.voided()
    }
}
