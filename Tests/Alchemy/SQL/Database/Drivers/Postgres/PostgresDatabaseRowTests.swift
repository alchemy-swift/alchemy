@testable import PostgresNIO
@testable import Alchemy
import AlchemyTest

final class PostgresDatabaseRowTests: TestCase<TestApp> {
    func testString() {
        XCTAssertEqual(try PostgresData(.string("foo")).toSQLValue(""), .string("foo"))
        XCTAssertEqual(try PostgresData(.string(nil)).toSQLValue(""), .string(nil))
    }
    
    func testInt() {
        XCTAssertEqual(try PostgresData(.int(1)).toSQLValue(""), .int(1))
        XCTAssertEqual(try PostgresData(.int(nil)).toSQLValue(""), .int(nil))
    }
    
    func testDouble() {
        XCTAssertEqual(try PostgresData(.double(2.0)).toSQLValue(""), .double(2.0))
        XCTAssertEqual(try PostgresData(.double(nil)).toSQLValue(""), .double(nil))
    }
    
    func testBool() {
        XCTAssertEqual(try PostgresData(.bool(false)).toSQLValue(""), .bool(false))
        XCTAssertEqual(try PostgresData(.bool(nil)).toSQLValue(""), .bool(nil))
    }
    
    func testDate() {
        let date = Date()
        XCTAssertEqual(try PostgresData(.date(date)).toSQLValue(""), .date(date))
        XCTAssertEqual(try PostgresData(.date(nil)).toSQLValue(""), .date(nil))
    }
    
    func testJson() {
        XCTAssertEqual(try PostgresData(.json(Data())).toSQLValue(""), .json(Data()))
        XCTAssertEqual(try PostgresData(.json(nil)).toSQLValue(""), .json(nil))
    }
    
    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(try PostgresData(.uuid(uuid)).toSQLValue(""), .uuid(uuid))
        XCTAssertEqual(try PostgresData(.uuid(nil)).toSQLValue(""), .uuid(nil))
    }
    
    func testUnsupportedTypeThrows() {
        XCTAssertThrowsError(try PostgresData(type: .time).toSQLValue(""))
    }
}
