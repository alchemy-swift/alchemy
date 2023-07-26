@testable
import Alchemy
import AlchemyTest

final class ModelPrimaryKeyTests: XCTestCase {
    func testPrimaryKeyFromSqlValue() {
        let uuid = UUID()
        XCTAssertEqual(try UUID(value: .string(uuid.uuidString)), uuid)
        XCTAssertThrowsError(try UUID(value: .int(1)))
        XCTAssertEqual(try Int(value: .int(1)), 1)
        XCTAssertThrowsError(try Int(value: .string("foo")))
        XCTAssertEqual(try String(value: .string("foo")), "foo")
        XCTAssertThrowsError(try String(value: .bool(false)))
    }
}
