@testable import MySQLNIO
@testable import Alchemy
import AlchemyTest

final class MySQLDatabaseRowTests: TestCase<TestApp> {
    func testString() {
        XCTAssertEqual(try MySQLData(.string("foo")).toSQLValue(""), .string("foo"))
        XCTAssertEqual(try MySQLData(.string(nil)).toSQLValue(""), .string(nil))
    }
    
    func testInt() {
        XCTAssertEqual(try MySQLData(.int(1)).toSQLValue(""), .int(1))
        XCTAssertEqual(try MySQLData(.int(nil)).toSQLValue(""), .int(nil))
    }
    
    func testDouble() {
        XCTAssertEqual(try MySQLData(.double(2.0)).toSQLValue(""), .double(2.0))
        XCTAssertEqual(try MySQLData(.double(nil)).toSQLValue(""), .double(nil))
    }
    
    func testBool() {
        XCTAssertEqual(try MySQLData(.bool(false)).toSQLValue(""), .bool(false))
        XCTAssertEqual(try MySQLData(.bool(nil)).toSQLValue(""), .bool(nil))
    }
    
    func testDate() {
        let date = Date()
        XCTAssertEqual(try MySQLData(.date(date)).toSQLValue(""), .date(date))
        XCTAssertEqual(try MySQLData(.date(nil)).toSQLValue(""), .date(nil))
    }
    
    func testJson() {
        XCTAssertEqual(try MySQLData(.json(Data())).toSQLValue(""), .json(Data()))
        XCTAssertEqual(try MySQLData(.json(nil)).toSQLValue(""), .json(nil))
    }
    
    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(try MySQLData(.uuid(uuid)).toSQLValue(""), .uuid(uuid))
        XCTAssertEqual(try MySQLData(.uuid(nil)).toSQLValue(""), .uuid(nil))
    }
    
    func testUnsupportedTypeThrows() {
        XCTAssertThrowsError(try MySQLData(type: .time, buffer: nil).toSQLValue(""))
    }
}
