@testable
import Alchemy
import AlchemyTest

final class MySQLDatabaseTests: TestCase<TestApp> {
    func testDatabase() throws {
        let db = Database.mysql(host: "localhost", database: "foo", username: "bar", password: "baz")
        guard let driver = db.driver as? Alchemy.MySQLDatabase else {
            XCTFail("The database driver should be MySQL.")
            return
        }
        
        XCTAssertEqual(try driver.pool.source.configuration.address().ipAddress, "::1")
        XCTAssertEqual(try driver.pool.source.configuration.address().port, 3306)
        XCTAssertEqual(driver.pool.source.configuration.database, "foo")
        XCTAssertEqual(driver.pool.source.configuration.username, "bar")
        XCTAssertEqual(driver.pool.source.configuration.password, "baz")
        XCTAssertTrue(driver.pool.source.configuration.tlsConfiguration == nil)
        try db.shutdown()
    }
    
    func testConfigIp() throws {
        let socket: Socket = .ip(host: "::1", port: 1234)
        let config = DatabaseConfig(socket: socket, database: "foo", username: "bar", password: "baz")
        let driver = MySQLDatabase(config: config)
        XCTAssertEqual(try driver.pool.source.configuration.address().ipAddress, "::1")
        XCTAssertEqual(try driver.pool.source.configuration.address().port, 1234)
        XCTAssertEqual(driver.pool.source.configuration.database, "foo")
        XCTAssertEqual(driver.pool.source.configuration.username, "bar")
        XCTAssertEqual(driver.pool.source.configuration.password, "baz")
        XCTAssertTrue(driver.pool.source.configuration.tlsConfiguration == nil)
        try driver.shutdown()
    }
    
    func testConfigSSL() throws {
        let socket: Socket = .ip(host: "::1", port: 1234)
        let config = DatabaseConfig(socket: socket, database: "foo", username: "bar", password: "baz", enableSSL: true)
        let driver = MySQLDatabase(config: config)
        XCTAssertEqual(try driver.pool.source.configuration.address().ipAddress, "::1")
        XCTAssertEqual(try driver.pool.source.configuration.address().port, 1234)
        XCTAssertEqual(driver.pool.source.configuration.database, "foo")
        XCTAssertEqual(driver.pool.source.configuration.username, "bar")
        XCTAssertEqual(driver.pool.source.configuration.password, "baz")
        XCTAssertTrue(driver.pool.source.configuration.tlsConfiguration != nil)
        try driver.shutdown()
    }
    
    func testConfigPath() throws {
        let socket: Socket = .unix(path: "/test")
        let config = DatabaseConfig(socket: socket, database: "foo", username: "bar", password: "baz")
        let driver = MySQLDatabase(config: config)
        XCTAssertEqual(try driver.pool.source.configuration.address().pathname, "/test")
        XCTAssertEqual(try driver.pool.source.configuration.address().port, nil)
        XCTAssertEqual(driver.pool.source.configuration.database, "foo")
        XCTAssertEqual(driver.pool.source.configuration.username, "bar")
        XCTAssertEqual(driver.pool.source.configuration.password, "baz")
        XCTAssertTrue(driver.pool.source.configuration.tlsConfiguration == nil)
        try driver.shutdown()
    }
}
