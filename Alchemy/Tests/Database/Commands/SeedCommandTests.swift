@testable
import Alchemy
import AlchemyTesting

@Suite(.mockContainer)
struct SeedCommandTests {
    @Test func seed() async throws {
        try await DB.fake(migrations: [SeedModel.Migrate()])
        DB.seeders = [Seeder1(), Seeder2()]
        try await SeedCommand(db: nil).run()
        #expect(Seeder1.didRun)
        #expect(Seeder2.didRun)
    }

    @Test(.disabled("need to enable selecting service from string"))
    func namedSeed() async throws {}
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
