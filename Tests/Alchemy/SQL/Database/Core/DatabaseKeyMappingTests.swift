import Alchemy
import XCTest

final class KeyMappingTests: XCTestCase {
    func testCustom() {
        let custom = KeyMapping.custom { "\($0)_1" }
        XCTAssertEqual(custom.encode("foo"), "foo_1")
    }
    
    func testSnakeCase() {
        let snakeCase = KeyMapping.convertToSnakeCase
        XCTAssertEqual(snakeCase.encode(""), "")
        XCTAssertEqual(snakeCase.encode("foo"), "foo")
        XCTAssertEqual(snakeCase.encode("fooBar"), "foo_bar")
        XCTAssertEqual(snakeCase.encode("AI"), "a_i")
        XCTAssertEqual(snakeCase.encode("testJSON"), "test_json")
        XCTAssertEqual(snakeCase.encode("testNumbers123"), "test_numbers123")
    }
}
