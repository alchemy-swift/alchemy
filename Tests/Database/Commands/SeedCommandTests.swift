@testable
import Alchemy
import AlchemyTest

final class SeedCommandTests: TestCase<TestApp> {
    func testSeed() async throws {
        let db = try await Database.fake(migrations: [SeedModel.Migrate()])
        db.seeders = [Seeder1(), Seeder2()]
        try await SeedCommand(db: nil).run()
        XCTAssertTrue(Seeder1.didRun)
        XCTAssertTrue(Seeder2.didRun)
    }
    
    func testNamedSeed() async throws {
        try await Database.fake()
        let db = try await Database.fake("a", migrations: [SeedModel.Migrate()])
        db.seeders = [Seeder3(), Seeder4()]
        
        try await app.run("db:seed", "seeder3", "--db", "a")
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
