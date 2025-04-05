@testable
import Alchemy
import AlchemyTesting

struct MigrateCommandTests: AppSuite {
    let app = TestApp()

    @Test func run() async throws {
        try await withApp { app in
            try await DB.fake()
            DB.migrations = [MigrationA()]
            XCTAssertFalse(MigrationA.didUp)
            XCTAssertFalse(MigrationA.didDown)

            try await MigrateCommand().run()
            XCTAssertTrue(MigrationA.didUp)
            XCTAssertFalse(MigrationA.didDown)

            try await app.run("migrate:rollback")
            XCTAssertTrue(MigrationA.didDown)
        }
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
