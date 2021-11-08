@testable import PostgresNIO
@testable import Alchemy
import AlchemyTest

final class PostgresDatabaseRowTests: TestCase<TestApp> {
    func testGet() {
        let row = PostgresDatabaseRow(.fooOneBar2)
        XCTAssertEqual(try row.get("foo"), .string("one"))
        XCTAssertEqual(try row.get("bar"), .int(2))
        XCTAssertThrowsError(try row.get("baz"))
    }
    
    func testNull() {
        XCTAssertEqual(try PostgresData(.null).toSQLValue(), .null)
    }
    
    func testString() {
        XCTAssertEqual(try PostgresData(.string("foo")).toSQLValue(), .string("foo"))
        XCTAssertEqual(try PostgresData(type: .varchar).toSQLValue(), .null)
    }
    
    func testInt() {
        XCTAssertEqual(try PostgresData(.int(1)).toSQLValue(), .int(1))
        XCTAssertEqual(try PostgresData(type: .int8).toSQLValue(), .null)
    }
    
    func testDouble() {
        XCTAssertEqual(try PostgresData(.double(2.0)).toSQLValue(), .double(2.0))
        XCTAssertEqual(try PostgresData(type: .float8).toSQLValue(), .null)
    }
    
    func testBool() {
        XCTAssertEqual(try PostgresData(.bool(false)).toSQLValue(), .bool(false))
        XCTAssertEqual(try PostgresData(type: .bool).toSQLValue(), .null)
    }
    
    func testDate() {
        let date = Date()
        XCTAssertEqual(try PostgresData(.date(date)).toSQLValue(), .date(date))
        XCTAssertEqual(try PostgresData(type: .date).toSQLValue(), .null)
    }
    
    func testJson() {
        XCTAssertEqual(try PostgresData(.json(Data())).toSQLValue(), .json(Data()))
        XCTAssertEqual(try PostgresData(type: .json).toSQLValue(), .null)
    }
    
    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(try PostgresData(.uuid(uuid)).toSQLValue(), .uuid(uuid))
        XCTAssertEqual(try PostgresData(type: .uuid).toSQLValue(), .null)
    }
    
    func testUnsupportedTypeThrows() {
        XCTAssertThrowsError(try PostgresData(type: .time).toSQLValue())
        XCTAssertThrowsError(try PostgresData(type: .point).toSQLValue("column"))
    }
}

extension PostgresRow {
    static let fooOneBar2 = PostgresRow(
        dataRow: .init(columns: [
            .init(value: ByteBuffer(string: "one")),
            .init(value: ByteBuffer(integer: 2))
        ]),
        lookupTable: .init(
            rowDescription: .init(
                fields: [
                    .init(
                        name: "foo",
                        tableOID: 0,
                        columnAttributeNumber: 0,
                        dataType: .varchar,
                        dataTypeSize: 3,
                        dataTypeModifier: 0,
                        formatCode: .text
                    ),
                    .init(
                        name: "bar",
                        tableOID: 0,
                        columnAttributeNumber: 0,
                        dataType: .int8,
                        dataTypeSize: 8,
                        dataTypeModifier: 0,
                        formatCode: .binary
                    ),
                ]),
            resultFormat: [.binary]))
}
