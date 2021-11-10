import AlchemyTest

final class SQLValueTests: XCTestCase {
    func testNull() {
        XCTAssertThrowsError(try SQLValue.null.int())
        XCTAssertThrowsError(try SQLValue.null.double())
        XCTAssertThrowsError(try SQLValue.null.bool())
        XCTAssertThrowsError(try SQLValue.null.string())
        XCTAssertThrowsError(try SQLValue.null.json())
        XCTAssertThrowsError(try SQLValue.null.date())
        XCTAssertThrowsError(try SQLValue.null.uuid("foo"))
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
        let jsonString = """
        {"foo":1}
        """
        XCTAssertEqual(try SQLValue.json(Data()).json(), Data())
        XCTAssertEqual(try SQLValue.string(jsonString).json(), jsonString.data(using: .utf8))
        XCTAssertThrowsError(try SQLValue.int(1).json())
    }
    
    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(try SQLValue.uuid(uuid).uuid(), uuid)
        XCTAssertEqual(try SQLValue.string(uuid.uuidString).uuid(), uuid)
        XCTAssertThrowsError(try SQLValue.string("").uuid())
        XCTAssertThrowsError(try SQLValue.int(1).uuid("foo"))
    }
}
