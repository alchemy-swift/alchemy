@testable
import Alchemy
import AlchemyTesting

@Suite(.mockContainer)
struct MigrateCommandTests: TestSuite {
    @Test func run() async throws {
        try await DB.fake()
        DB.migrations = [MigrationA()]
        #expect(!MigrationA.didUp)
        #expect(!MigrationA.didDown)

        try await MigrateCommand().run()
        #expect(MigrationA.didUp)
        #expect(!MigrationA.didDown)

        try await App.run("migrate:rollback")
        #expect(MigrationA.didDown)
    }
}

private struct MigrationA: Migration {
    static var didUp: Bool = false
    static var didDown: Bool = false
    
    func up(db: Database) async throws {
        MigrationA.didUp = true
    }

    func down(db: Database) async throws {
        MigrationA.didDown = true
    }
}
