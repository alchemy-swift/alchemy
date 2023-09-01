@testable
import Alchemy
import AlchemyTest

final class DatabaseMigrationTests: TestCase<TestApp> {
    func testMigration() async throws {
        let db = try await Database.fake()
        try await db.rollback()
        db.migrations = [MigrationA()]
        try await db.migrate()
        AssertEqual(try await Database.AppliedMigration.all().count, 1)
        db.migrations.append(MigrationB())
        try await db.migrate()
        AssertEqual(try await Database.AppliedMigration.all().count, 2)
        try await db.rollback()
        AssertEqual(try await Database.AppliedMigration.all().count, 1)
    }
}

private struct MigrationA: Migration {
    func up(db: Database) async throws {}
    func down(db: Database) async throws {}
}

private struct MigrationB: Migration {
    func up(db: Database) async throws {}
    func down(db: Database) async throws {}
}
