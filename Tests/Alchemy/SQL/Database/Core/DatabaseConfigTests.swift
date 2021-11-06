import AlchemyTest

final class DatabaseConfigTests: XCTestCase {
    func testInit() {
        let socket = Socket.ip(host: "http://localhost", port: 1234)
        let config = DatabaseConfig(socket: socket, database: "foo", username: "bar", password: "baz")
        XCTAssertEqual(config.socket, socket)
        XCTAssertEqual(config.database, "foo")
        XCTAssertEqual(config.username, "bar")
        XCTAssertEqual(config.password, "baz")
    }
}
