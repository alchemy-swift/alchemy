@testable
import Alchemy
import AlchemyTest

final class DatabaseSeederTests: TestCase<TestApp> {
    func testSeeder() async throws {
        Database.fake(
            migrations: [
                SeedModel.Migrate(),
                OtherSeedModel.Migrate()],
            seeders: [TestSeeder()])
        
        AssertEqual(try await SeedModel.all().count, 10)
        AssertEqual(try await OtherSeedModel.all().count, 0)
        
        try await Database.default.seed(with: OtherSeeder())
        AssertEqual(try await OtherSeedModel.all().count, 999)
    }
    
    func testSeedWithNames() async throws {
        Database.fake(
            migrations: [
                SeedModel.Migrate(),
                OtherSeedModel.Migrate()])
        
        Database.default.seeders = [
            TestSeeder(),
            OtherSeeder()
        ]
        
        try await Database.default.seed(names: ["otherseeder"])
        AssertEqual(try await SeedModel.all().count, 0)
        AssertEqual(try await OtherSeedModel.all().count, 999)
        
        do {
            try await Database.default.seed(names: ["foo"])
            XCTFail("Unknown seeder name should throw")
        } catch {}
    }
}

private struct TestSeeder: Seeder {
    func run() async throws {
        try await SeedModel.seed(10)
    }
}

private struct OtherSeeder: Seeder {
    func run() async throws {
        try await OtherSeedModel.seed(999)
    }
}
