@testable
import Alchemy
import AlchemyTest
import NIOSSL

final class PostgresDatabaseTests: TestCase<TestApp> {
    func testDatabase() throws {
        let db = Database.postgres(host: "127.0.0.1", database: "foo", username: "bar", password: "baz")
        guard let provider = db.provider as? Alchemy.PostgresDatabase else {
            XCTFail("The database provider should be PostgreSQL.")
            return
        }
        
        XCTAssertEqual(try provider.pool.source.configuration.address().ipAddress, "127.0.0.1")
        XCTAssertEqual(try provider.pool.source.configuration.address().port, 5432)
        XCTAssertEqual(provider.pool.source.configuration.database, "foo")
        XCTAssertEqual(provider.pool.source.configuration.username, "bar")
        XCTAssertEqual(provider.pool.source.configuration.password, "baz")
        XCTAssertTrue(provider.pool.source.configuration.tlsConfiguration == nil)
        try db.shutdown()
    }
    
    func testConfigIp() throws {
        let socket: Socket = .ip(host: "127.0.0.1", port: 1234)
        let provider = PostgresDatabase(socket: socket, database: "foo", username: "bar", password: "baz")
        XCTAssertEqual(try provider.pool.source.configuration.address().ipAddress, "127.0.0.1")
        XCTAssertEqual(try provider.pool.source.configuration.address().port, 1234)
        XCTAssertEqual(provider.pool.source.configuration.database, "foo")
        XCTAssertEqual(provider.pool.source.configuration.username, "bar")
        XCTAssertEqual(provider.pool.source.configuration.password, "baz")
        XCTAssertTrue(provider.pool.source.configuration.tlsConfiguration == nil)
        try provider.shutdown()
    }
    
    func testConfigSSL() throws {
        let socket: Socket = .ip(host: "127.0.0.1", port: 1234)
        let tlsConfig = TLSConfiguration.makeClientConfiguration()
        let provider = PostgresDatabase(socket: socket, database: "foo", username: "bar", password: "baz", tlsConfiguration: tlsConfig)
        XCTAssertEqual(try provider.pool.source.configuration.address().ipAddress, "127.0.0.1")
        XCTAssertEqual(try provider.pool.source.configuration.address().port, 1234)
        XCTAssertEqual(provider.pool.source.configuration.database, "foo")
        XCTAssertEqual(provider.pool.source.configuration.username, "bar")
        XCTAssertEqual(provider.pool.source.configuration.password, "baz")
        XCTAssertTrue(provider.pool.source.configuration.tlsConfiguration != nil)
        try provider.shutdown()
    }
    
    func testConfigPath() throws {
        let socket: Socket = .unix(path: "/test")
        let provider = PostgresDatabase(socket: socket, database: "foo", username: "bar", password: "baz")
        XCTAssertEqual(try provider.pool.source.configuration.address().pathname, "/test")
        XCTAssertEqual(try provider.pool.source.configuration.address().port, nil)
        XCTAssertEqual(provider.pool.source.configuration.database, "foo")
        XCTAssertEqual(provider.pool.source.configuration.username, "bar")
        XCTAssertEqual(provider.pool.source.configuration.password, "baz")
        XCTAssertTrue(provider.pool.source.configuration.tlsConfiguration == nil)
        try provider.shutdown()
    }
    
    func testPositionBinds() {
        let query = "select * from cats where name = ? and age > ?"
        XCTAssertEqual(query.positionPostgresBinds(), "select * from cats where name = $1 and age > $2")
    }
}
