import Foundation
import NIO

let kMigrationTable = "migrations"

extension Database {
    /// Applies `migration.up` to this database.
    public func migrate<M: Migration>(_ migration: M) {
        let migrationName = name(of: M.self)
        // Check if migration already run
        let schema = Schema()
        migration.up(schema: schema)
        self.runConsecutively(statements: schema.statements)
        // Flag migration as run
    }

    /// Applies `migration.down` to the database.
    public func rollback<M: Migration>(_ migration: M) {
        let migrationName = name(of: M.self)
    }
    
    private func checkMigrationExists() -> EventLoopFuture<Bool> {
        fatalError()
    }
    
    private func markMigrationRun() -> EventLoopFuture<Void> {
        fatalError()
    }
}

extension Database {
    func runConsecutively(statements: [SQL]) -> EventLoopFuture<Void> {
        guard let first = statements.first else {
            return Loop.current.future()
        }
        
        var elf = self.runQuery(first.query, values: first.bindings, on: Loop.current)
        for statement in statements {
            elf = elf.flatMap { _ in self.runQuery(statement.query, values: statement.bindings,
                                                   on: Loop.current) }
        }
        return elf.voided()
    }
}
