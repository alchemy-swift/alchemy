//import AlchemyTest
//
//final class DatabaseConfigTests: TestCase<TestApp> {
//    func testConfig() {
//        let config = Database.Config(
//            databases: [
//                .default: .memory,
//                1: .memory,
//                2: .memory
//            ],
//            migrations: [Migration1()],
//            seeders: [TestSeeder()],
//            redis: [
//                .default: .testing,
//                1: .testing,
//                2: .testing
//            ])
//        Database.configure(with: config)
//        XCTAssertNotNil(Container.resolve(Database.self, identifier: Database.Identifier.default))
//        XCTAssertNotNil(Container.resolve(Database.self, identifier: 1))
//        XCTAssertNotNil(Container.resolve(Database.self, identifier: 2))
//        XCTAssertNotNil(Container.resolve(RedisClient.self, identifier: RedisClient.Identifier.default))
//        XCTAssertNotNil(Container.resolve(RedisClient.self, identifier: 1))
//        XCTAssertNotNil(Container.resolve(RedisClient.self, identifier: 2))
//        XCTAssertEqual(DB.migrations.count, 1)
//        XCTAssertEqual(DB.seeders.count, 1)
//    }
//}
//
//private struct TestSeeder: Seeder {
//    func run() async throws {}
//}
