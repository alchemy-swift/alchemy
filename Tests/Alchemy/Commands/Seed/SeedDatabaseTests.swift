@testable
import Alchemy
import AlchemyTest

final class SeedDatabaseTests: TestCase<TestApp> {
    func testSeed() async throws {
        let db = Database.fake(migrations: [SeedModel.Migrate()])
        db.seeders = [Seeder1(), Seeder2()]
        try SeedDatabase(database: nil).run()
        try app.lifecycle.startAndWait()
        XCTAssertTrue(Seeder1.didRun)
        XCTAssertTrue(Seeder2.didRun)
    }
    
    func testNamedSeed() async throws {
        let db = Database.fake("a", migrations: [SeedModel.Migrate()])
        db.seeders = [Seeder3(), Seeder4()]
        
        try app.start("db:seed", "seeder3", "--database", "a")
        app.wait()
        
        XCTAssertTrue(Seeder3.didRun)
        XCTAssertFalse(Seeder4.didRun)
    }
}

private struct Seeder1: Seeder {
    static var didRun: Bool = false
    func run() async throws { Seeder1.didRun = true }
}

private struct Seeder2: Seeder {
    static var didRun: Bool = false
    func run() async throws { Seeder2.didRun = true }
}

private struct Seeder3: Seeder {
    static var didRun: Bool = false
    func run() async throws { Seeder3.didRun = true }
}

private struct Seeder4: Seeder {
    static var didRun: Bool = false
    func run() async throws { Seeder4.didRun = true }
}
