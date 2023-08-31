@testable
import Alchemy
import AlchemyTest

final class ParameterTests: XCTestCase {
    func testStringConversion() {
        XCTAssertEqual(Request.Parameter(key: "foo", value: "bar").string(), "bar")
    }
    
    func testIntConversion() throws {
        XCTAssertEqual(try Request.Parameter(key: "foo", value: "1").int(), 1)
        XCTAssertThrowsError(try Request.Parameter(key: "foo", value: "foo").int())
    }
    
    func testUuidConversion() throws {
        let uuid = UUID()
        XCTAssertEqual(try Request.Parameter(key: "foo", value: uuid.uuidString).uuid(), uuid)
        XCTAssertThrowsError(try Request.Parameter(key: "foo", value: "foo").uuid())
    }
}
