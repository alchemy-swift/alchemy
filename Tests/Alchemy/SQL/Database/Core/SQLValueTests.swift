import AlchemyTest

final class SQLValueTests: XCTestCase {
    func testNull() {
        XCTAssertThrowsError(try SQLParameterConvertible.null.int())
        XCTAssertThrowsError(try SQLParameterConvertible.null.double())
        XCTAssertThrowsError(try SQLParameterConvertible.null.bool())
        XCTAssertThrowsError(try SQLParameterConvertible.null.string())
        XCTAssertThrowsError(try SQLParameterConvertible.null.json())
        XCTAssertThrowsError(try SQLParameterConvertible.null.date())
        XCTAssertThrowsError(try SQLParameterConvertible.null.uuid("foo"))
    }
    
    func testInt() {
        XCTAssertEqual(try SQLParameterConvertible.int(1).int(), 1)
        XCTAssertThrowsError(try SQLParameterConvertible.string("foo").int())
    }
    
    func testDouble() {
        XCTAssertEqual(try SQLParameterConvertible.double(1.0).double(), 1.0)
        XCTAssertThrowsError(try SQLParameterConvertible.string("foo").double())
    }
    
    func testBool() {
        XCTAssertEqual(try SQLParameterConvertible.bool(false).bool(), false)
        XCTAssertEqual(try SQLParameterConvertible.int(1).bool(), true)
        XCTAssertThrowsError(try SQLParameterConvertible.string("foo").bool())
    }
    
    func testString() {
        XCTAssertEqual(try SQLParameterConvertible.string("foo").string(), "foo")
        XCTAssertThrowsError(try SQLParameterConvertible.int(1).string())
    }
    
    func testDate() {
        let date = Date()
        XCTAssertEqual(try SQLParameterConvertible.date(date).date(), date)
        XCTAssertThrowsError(try SQLParameterConvertible.int(1).date())
    }
    
    func testDateIso8601() {
        let date = Date()
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        let roundedDate = formatter.date(from: dateString) ?? Date()
        XCTAssertEqual(try SQLParameterConvertible.string(formatter.string(from: date)).date(), roundedDate)
        XCTAssertThrowsError(try SQLParameterConvertible.string("").date())
    }
    
    func testJson() {
        let jsonString = """
        {"foo":1}
        """
        XCTAssertEqual(try SQLParameterConvertible.json(Data()).json(), Data())
        XCTAssertEqual(try SQLParameterConvertible.string(jsonString).json(), jsonString.data(using: .utf8))
        XCTAssertThrowsError(try SQLParameterConvertible.int(1).json())
    }
    
    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(try SQLParameterConvertible.uuid(uuid).uuid(), uuid)
        XCTAssertEqual(try SQLParameterConvertible.string(uuid.uuidString).uuid(), uuid)
        XCTAssertThrowsError(try SQLParameterConvertible.string("").uuid())
        XCTAssertThrowsError(try SQLParameterConvertible.int(1).uuid("foo"))
    }
    
    func testDescription() {
        XCTAssertEqual(SQLParameterConvertible.int(0).description, "SQLValue.int(0)")
        XCTAssertEqual(SQLParameterConvertible.double(1.23).description, "SQLValue.double(1.23)")
        XCTAssertEqual(SQLParameterConvertible.bool(true).description, "SQLValue.bool(true)")
        XCTAssertEqual(SQLParameterConvertible.string("foo").description, "SQLValue.string(`foo`)")
        let date = Date()
        XCTAssertEqual(SQLParameterConvertible.date(date).description, "SQLValue.date(\(date))")
        let jsonString = """
        {"foo":"bar"}
        """
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        XCTAssertEqual(SQLParameterConvertible.json(jsonData).description, "SQLValue.json(\(jsonString))")
        let uuid = UUID()
        XCTAssertEqual(SQLParameterConvertible.uuid(uuid).description, "SQLValue.uuid(\(uuid.uuidString))")
        XCTAssertEqual(SQLParameterConvertible.null.description, "SQLValue.null")
    }
}
