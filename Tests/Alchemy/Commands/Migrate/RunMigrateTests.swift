@testable
import Alchemy
import AlchemyTest

final class RunMigrateTests: TestCase<TestApp> {
    func testRun() async throws {
        let db = try await Database.fake()
        db.migrations = [MigrationA()]
        XCTAssertFalse(MigrationA.didUp)
        XCTAssertFalse(MigrationA.didDown)
        
        try await MigrateCommand(rollback: false).start()
        XCTAssertTrue(MigrationA.didUp)
        XCTAssertFalse(MigrationA.didDown)
        
        try app.start("migrate", "--rollback")
        app.wait()
        
        XCTAssertTrue(MigrationA.didDown)
    }
}

private struct MigrationA: Migration {
    static var didUp: Bool = false
    static var didDown: Bool = false
    func up(schema: Schema) { MigrationA.didUp = true }
    func down(schema: Schema) { MigrationA.didDown = true }
}
