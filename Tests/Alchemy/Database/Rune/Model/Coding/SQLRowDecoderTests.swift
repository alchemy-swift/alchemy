@testable
import Alchemy
import AlchemyTest

final class SQLRowDecoderTests: XCTestCase {
    func testDecodeThrowing() throws {
        let row: SQLRow = [:]
        let decoder = SQLRowDecoder(row: row, keyMapping: .useDefaultKeys, jsonDecoder: JSONDecoder())
        XCTAssertThrowsError(try decoder.singleValueContainer())
        XCTAssertThrowsError(try decoder.unkeyedContainer())
        
        let keyed = try decoder.container(keyedBy: DummyKeys.self)
        XCTAssertThrowsError(try keyed.nestedUnkeyedContainer(forKey: .foo))
        XCTAssertThrowsError(try keyed.nestedContainer(keyedBy: DummyKeys.self, forKey: .foo))
        XCTAssertThrowsError(try keyed.superDecoder())
        XCTAssertThrowsError(try keyed.superDecoder(forKey: .foo))
    }
}

private enum DummyKeys: String, CodingKey {
    case foo
}
