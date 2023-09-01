@testable
import Alchemy
import AlchemyTest
import NIOSSL

final class MySQLDatabaseTests: TestCase<TestApp> {
    func testDatabase() async throws {
        let db = Database.mysql(host: "127.0.0.1", database: "foo", username: "bar", password: "baz")
        guard let provider = db.provider as? Alchemy.MySQLDatabaseProvider else {
            XCTFail("The database provider should be MySQL.")
            return
        }
        
        XCTAssertEqual(try provider.pool.source.address().ipAddress, "127.0.0.1")
        XCTAssertEqual(try provider.pool.source.address().port, 3306)
        XCTAssertEqual(provider.pool.source.database, "foo")
        XCTAssertEqual(provider.pool.source.username, "bar")
        XCTAssertEqual(provider.pool.source.password, "baz")
        try await db.shutdown()
    }
}
