@testable import MySQLNIO
@testable import Alchemy
import AlchemyTest

final class MySQLDatabaseRowTests: TestCase<TestApp> {
    func testNil() {
        XCTAssertEqual(MySQLData(.null).sqlValue, .null)
    }
    
    func testString() {
        XCTAssertEqual(MySQLData(.string("foo")).sqlValue, .string("foo"))
        XCTAssertEqual(MySQLData(type: .string, buffer: nil).sqlValue, .null)
    }
    
    func testInt() {
        XCTAssertEqual(MySQLData(.int(1)).sqlValue, .int(1))
        XCTAssertEqual(MySQLData(type: .long, buffer: nil).sqlValue, .null)
    }
    
    func testDouble() {
        XCTAssertEqual(MySQLData(.double(2.0)).sqlValue, .double(2.0))
        XCTAssertEqual(MySQLData(type: .float, buffer: nil).sqlValue, .null)
    }
    
    func testBool() {
        XCTAssertEqual(MySQLData(.bool(false)).sqlValue, .bool(false))
        XCTAssertEqual(MySQLData(type: .tiny, buffer: nil).sqlValue, .null)
    }
    
    func testDate() throws {
        let date = Date()
        // MySQLNIO occasionally loses some millisecond precision; round off.
        let roundedDate = Date(timeIntervalSince1970: TimeInterval((Int(date.timeIntervalSince1970) / 1000) * 1000))
        XCTAssertEqual(MySQLData(.date(roundedDate)).sqlValue, .date(roundedDate))
        XCTAssertEqual(MySQLData(type: .date, buffer: nil).sqlValue, .null)
    }
    
    func testJson() {
        XCTAssertEqual(MySQLData(.json(ByteBuffer())).sqlValue, .json(ByteBuffer()))
        XCTAssertEqual(MySQLData(type: .json, buffer: nil).sqlValue, .null)
    }
    
    func testUuid() {
        let uuid = UUID()
        // Store as a string in MySQL
        XCTAssertEqual(MySQLData(.uuid(uuid)).sqlValue, .string(uuid.uuidString))
    }
}
