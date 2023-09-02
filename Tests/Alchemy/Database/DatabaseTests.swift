import AlchemyTest

final class DatabaseTests: TestCase<TestApp> {
    func testPlugin() async throws {
        let plugin = Databases(
            default: 1,
            databases: [
                1: .memory,
                2: .memory
            ],
            migrations: [Migration1()],
            seeders: [TestSeeder()],
            defaultRedis: 1,
            redis: [
                1: .testing,
                2: .testing
            ])
        plugin.registerServices(in: app)
        XCTAssertNotNil(Container.resolve(Database.self))
        XCTAssertNotNil(Container.resolve(Database.self, id: 1))
        XCTAssertNotNil(Container.resolve(Database.self, id: 2))
        XCTAssertNotNil(Container.resolve(RedisClient.self))
        XCTAssertNotNil(Container.resolve(RedisClient.self, id: 1))
        XCTAssertNotNil(Container.resolve(RedisClient.self, id: 2))
        XCTAssertEqual(DB.migrations.count, 1)
        XCTAssertEqual(DB.seeders.count, 1)
        try await plugin.shutdownServices(in: app)
    }
}

private struct TestSeeder: Seeder {
    func run() async throws {
        //
    }
}
