import Alchemy
import XCTest

final class DatabaseKeyMappingTests: XCTestCase {
    func testCustom() {
        let custom = DatabaseKeyMapping.custom { "\($0)_1" }
        XCTAssertEqual(custom.map(input: "foo"), "foo_1")
    }
    
    func testSnakeCase() {
        let snakeCase = DatabaseKeyMapping.convertToSnakeCase
        XCTAssertEqual(snakeCase.map(input: ""), "")
        XCTAssertEqual(snakeCase.map(input: "foo"), "foo")
        XCTAssertEqual(snakeCase.map(input: "fooBar"), "foo_bar")
        XCTAssertEqual(snakeCase.map(input: "AI"), "a_i")
    }
}
