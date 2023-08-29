//@testable import MySQLNIO
//@testable import Alchemy
//import AlchemyTest
//
//final class MySQLDatabaseRowTests: TestCase<TestApp> {
//    func testGet() throws {
//        let row = try SQLRow(mysql: .fooOneBar2)
//        XCTAssertEqual(row["foo"], .string("one"))
//        XCTAssertEqual(row["bar"], .int(2))
//        XCTAssertFalse(row.contains("baz"))
//    }
//    
//    func testNil() {
//        XCTAssertEqual(try MySQLData(.null).toSQLValue(), .null)
//    }
//    
//    func testString() {
//        XCTAssertEqual(try MySQLData(.string("foo")).toSQLValue(), .string("foo"))
//        XCTAssertEqual(try MySQLData(type: .string, buffer: nil).toSQLValue(), .null)
//    }
//    
//    func testInt() {
//        XCTAssertEqual(try MySQLData(.int(1)).toSQLValue(), .int(1))
//        XCTAssertEqual(try MySQLData(type: .long, buffer: nil).toSQLValue(), .null)
//    }
//    
//    func testDouble() {
//        XCTAssertEqual(try MySQLData(.double(2.0)).toSQLValue(), .double(2.0))
//        XCTAssertEqual(try MySQLData(type: .float, buffer: nil).toSQLValue(), .null)
//    }
//    
//    func testBool() {
//        XCTAssertEqual(try MySQLData(.bool(false)).toSQLValue(), .bool(false))
//        XCTAssertEqual(try MySQLData(type: .tiny, buffer: nil).toSQLValue(), .null)
//    }
//    
//    func testDate() throws {
//        let date = Date()
//        // MySQLNIO occasionally loses some millisecond precision; round off.
//        let roundedDate = Date(timeIntervalSince1970: TimeInterval((Int(date.timeIntervalSince1970) / 1000) * 1000))
//        XCTAssertEqual(try MySQLData(.date(roundedDate)).toSQLValue(), .date(roundedDate))
//        XCTAssertEqual(try MySQLData(type: .date, buffer: nil).toSQLValue(), .null)
//    }
//    
//    func testJson() {
//        XCTAssertEqual(try MySQLData(.json(Data())).toSQLValue(), .json(Data()))
//        XCTAssertEqual(try MySQLData(type: .json, buffer: nil).toSQLValue(), .null)
//    }
//    
//    func testUuid() {
//        let uuid = UUID()
//        // Store as a string in MySQL
//        XCTAssertEqual(try MySQLData(.uuid(uuid)).toSQLValue(), .string(uuid.uuidString))
//    }
//    
//    func testUnsupportedTypeThrows() {
//        XCTAssertThrowsError(try MySQLData(type: .time, buffer: nil).toSQLValue())
//        XCTAssertThrowsError(try MySQLData(type: .time, buffer: nil).toSQLValue("fake"))
//    }
//}
//
//extension MySQLRow {
//    static let fooOneBar2 = MySQLRow(
//        format: .text,
//        columnDefinitions: [
//            .init(
//                catalog: "",
//                schema: "",
//                table: "",
//                orgTable: "",
//                name: "foo",
//                orgName: "",
//                characterSet: .utf8,
//                columnLength: 3,
//                columnType: .varchar,
//                flags: [],
//                decimals: 0),
//            .init(
//                catalog: "",
//                schema: "",
//                table: "",
//                orgTable: "",
//                name: "bar",
//                orgName: "",
//                characterSet: .utf8,
//                columnLength: 8,
//                columnType: .long,
//                flags: [],
//                decimals: 0)
//        ],
//        values: [
//            .init(string: "one"),
//            .init(string: "2"),
//        ])
//}
