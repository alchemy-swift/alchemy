@testable import SQLiteNIO
@testable import Alchemy
import AlchemyTest

final class SQLiteRowTests: TestCase<TestApp> {
    func testGet() throws {
        let row = try SQLRow(sqlite: .fooOneBar2)
        XCTAssertEqual(row["foo"], .string("one"))
        XCTAssertEqual(row["bar"], .int(2))
        XCTAssertFalse(row.contains("baz"))
    }
    
    func testNull() {
        XCTAssertEqual(try SQLiteData(.null).toSQLValue(), .null)
    }
    
    func testString() {
        XCTAssertEqual(try SQLiteData(.string("foo")).toSQLValue(), .string("foo"))
    }
    
    func testInt() {
        XCTAssertEqual(try SQLiteData(.int(1)).toSQLValue(), .int(1))
    }
    
    func testDouble() {
        XCTAssertEqual(try SQLiteData(.double(2.0)).toSQLValue(), .double(2.0))
    }
    
    func testBool() {
        XCTAssertEqual(try SQLiteData(.bool(false)).toSQLValue(), .int(0))
        XCTAssertEqual(try SQLiteData(.bool(true)).toSQLValue(), .int(1))
    }
    
    func testDate() {
        let date = Date()
        let dateString = SQLParameterConvertible.iso8601DateFormatter.string(from: date)
        XCTAssertEqual(try SQLiteData(.date(date)).toSQLValue(), .string(dateString))
    }
    
    func testJson() {
        let jsonString = """
        {"foo":"one","bar":2}
        """
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        XCTAssertEqual(try SQLiteData(.json(jsonData)).toSQLValue(), .string(jsonString))
        let invalidBytes: [UInt8] = [0xFF, 0xD9]
        XCTAssertEqual(try SQLiteData(.json(Data(bytes: invalidBytes, count: 2))).toSQLValue(), .null)
    }
    
    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(try SQLiteData(.uuid(uuid)).toSQLValue(), .string(uuid.uuidString))
    }
    
    func testUnsupportedTypeThrows() {
        XCTAssertThrowsError(try SQLiteData.blob(ByteBuffer()).toSQLValue())
    }
}

extension SQLiteRow {
    static let fooOneBar2 = SQLiteRow(
        columnOffsets: .init(offsets: [
            ("foo", 0),
            ("bar", 1),
        ]),
        data: [
            .text("one"),
            .integer(2)
        ])
}
