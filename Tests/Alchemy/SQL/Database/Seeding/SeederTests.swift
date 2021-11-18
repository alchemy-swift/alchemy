import AlchemyTest

final class SeederTests: TestCase<TestApp> {
    func testSeeder() async throws {
        Database.fake(migrations: [SeedModel.Migrate()])
        
        try await SeedModel.seed()
        AssertEqual(try await SeedModel.all().count, 1)
        
        try await SeedModel.seed(1000)
        AssertEqual(try await SeedModel.all().count, 1001)
    }
}
