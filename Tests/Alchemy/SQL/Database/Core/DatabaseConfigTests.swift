import AlchemyTest

final class DatabaseConfigTests: TestCase<TestApp> {
    func testInit() {
        let socket = Socket.ip(host: "http://localhost", port: 1234)
        let config = DatabaseConfig(socket: socket, database: "foo", username: "bar", password: "baz")
        XCTAssertEqual(config.socket, socket)
        XCTAssertEqual(config.database, "foo")
        XCTAssertEqual(config.username, "bar")
        XCTAssertEqual(config.password, "baz")
    }
    
    func testConfig() {
        let config = Database.Config(
            databases: [
                .default: .memory,
                1: .memory,
                2: .memory
            ],
            migrations: [Migration1()],
            seeders: [TestSeeder()],
            redis: [
                .default: .testing,
                1: .testing,
                2: .testing
            ])
        Database.configure(using: config)
        XCTAssertNotNil(Database.resolveOptional(.default))
        XCTAssertNotNil(Database.resolveOptional(1))
        XCTAssertNotNil(Database.resolveOptional(2))
        XCTAssertNotNil(Redis.resolveOptional(.default))
        XCTAssertNotNil(Redis.resolveOptional(1))
        XCTAssertNotNil(Redis.resolveOptional(2))
        XCTAssertEqual(Database.default.migrations.count, 1)
        XCTAssertEqual(Database.default.seeders.count, 1)
    }
}

private struct TestSeeder: Seeder {
    func run() async throws {}
}
