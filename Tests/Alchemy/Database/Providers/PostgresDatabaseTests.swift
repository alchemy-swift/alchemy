@testable
import Alchemy
import AlchemyTest
import NIOSSL

final class PostgresDatabaseTests: TestCase<TestApp> {
    func testDatabase() async throws {
        let db = Database.postgres(host: "127.0.0.1", database: "foo", username: "bar", password: "baz")
        guard let provider = db.provider as? Alchemy.PostgresDatabaseProvider else {
            XCTFail("The database provider should be PostgreSQL.")
            return
        }
        
        XCTAssertEqual(provider.pool.source.configuration.host, "127.0.0.1")
        XCTAssertEqual(provider.pool.source.configuration.port, 5432)
        XCTAssertEqual(provider.pool.source.configuration.database, "foo")
        XCTAssertEqual(provider.pool.source.configuration.username, "bar")
        XCTAssertEqual(provider.pool.source.configuration.password, "baz")
        try await db.shutdown()
    }

    func testPositionBinds() {
        let query = "select * from cats where name = ? and age > ?"
        XCTAssertEqual(query.positionPostgresBinds(), "select * from cats where name = $1 and age > $2")
    }
}
