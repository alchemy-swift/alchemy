@testable
import Alchemy
import AlchemyTest

final class ParameterTests: XCTestCase {
    func testStringConversion() {
        XCTAssertEqual(Parameter(key: "foo", value: "bar").string(), "bar")
    }
    
    func testIntConversion() throws {
        XCTAssertEqual(try Parameter(key: "foo", value: "1").int(), 1)
        XCTAssertThrowsError(try Parameter(key: "foo", value: "foo").int())
    }
    
    func testUuidConversion() throws {
        let uuid = UUID()
        XCTAssertEqual(try Parameter(key: "foo", value: uuid.uuidString).uuid(), uuid)
        XCTAssertThrowsError(try Parameter(key: "foo", value: "foo").uuid())
    }
}
