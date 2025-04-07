@testable
import Alchemy
import AlchemyTesting

@Suite(.mockTestApp)
struct MigrationTests {
    private let m1 = Migration1()
    private let m2 = Migration2()
    private let m3 = Migration3()

    @Test func migrationNames() {
        #expect(m1.name == "migration1")
        #expect(m2.name == "migration2")
        #expect(m3.name == "migration3")
    }

    @Test func databaseMigration() async throws {
        try await DB.fake()
        try await DB.rollback()
        DB.migrations = [MigrationA()]
        try await DB.migrate()
        #expect(try await Database.AppliedMigration.all().count == 1)
        DB.migrations.append(MigrationB())
        try await DB.migrate()
        #expect(try await Database.AppliedMigration.all().count == 2)
        try await DB.rollback()
        #expect(try await Database.AppliedMigration.all().count == 1)
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
