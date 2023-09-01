import AlchemyTest

final class SeederTests: TestCase<TestApp> {
    func testSeeder() async throws {
        try await Database.fake(migrations: [SeedModel.Migrate()])
        
        try await SeedModel.seed()
        AssertEqual(try await SeedModel.all().count, 1)
        
        try await SeedModel.seed(10)
        AssertEqual(try await SeedModel.all().count, 11)
    }
}
