import AlchemyTest

final class SQLValueTests: XCTestCase {
    func testNil() {
        XCTAssertTrue(SQLValue.int(nil).isNil)
        XCTAssertTrue(SQLValue.double(nil).isNil)
        XCTAssertTrue(SQLValue.bool(nil).isNil)
        XCTAssertTrue(SQLValue.string(nil).isNil)
        XCTAssertTrue(SQLValue.date(nil).isNil)
        XCTAssertTrue(SQLValue.json(nil).isNil)
        XCTAssertTrue(SQLValue.uuid(nil).isNil)
    }
    
    func testInt() {
        XCTAssertEqual(try SQLValue.int(1).int(), 1)
        XCTAssertThrowsError(try SQLValue.string("foo").int())
    }
    
    func testDouble() {
        XCTAssertEqual(try SQLValue.double(1.0).double(), 1.0)
        XCTAssertThrowsError(try SQLValue.string("foo").double())
    }
    
    func testBool() {
        XCTAssertEqual(try SQLValue.bool(false).bool(), false)
        XCTAssertEqual(try SQLValue.int(1).bool(), true)
        XCTAssertThrowsError(try SQLValue.string("foo").bool())
    }
    
    func testString() {
        XCTAssertEqual(try SQLValue.string("foo").string(), "foo")
        XCTAssertThrowsError(try SQLValue.int(1).string())
    }
    
    func testDate() {
        let date = Date()
        XCTAssertEqual(try SQLValue.date(date).date(), date)
        XCTAssertThrowsError(try SQLValue.int(1).date())
    }
    
    func testDateIso8601() {
        let date = Date()
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        let roundedDate = formatter.date(from: dateString) ?? Date()
        XCTAssertEqual(try SQLValue.string(formatter.string(from: date)).date(), roundedDate)
        XCTAssertThrowsError(try SQLValue.string("").date())
    }
    
    func testJson() {
        XCTAssertEqual(try SQLValue.json(Data()).json(), Data())
        XCTAssertThrowsError(try SQLValue.string("foo").json())
    }
    
    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(try SQLValue.uuid(uuid).uuid(), uuid)
        XCTAssertThrowsError(try SQLValue.string("foo").uuid())
    }
}
