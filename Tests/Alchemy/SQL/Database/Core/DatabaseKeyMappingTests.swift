import Alchemy
import XCTest

final class KeyMappingTests: XCTestCase {
    func testCustom() {
        let custom = KeyMapping.custom(to: { "\($0)_1" }, from: { String($0.dropLast(2)) }) 
        XCTAssertEqual(custom.encode("foo"), "foo_1")
    }
    
    func testSnakeCase() {
        let snakeCase = KeyMapping.snakeCase
        XCTAssertEqual(snakeCase.encode(""), "")
        XCTAssertEqual(snakeCase.encode("foo"), "foo")
        XCTAssertEqual(snakeCase.encode("fooBar"), "foo_bar")
        XCTAssertEqual(snakeCase.encode("AI"), "a_i")
        XCTAssertEqual(snakeCase.encode("testJSON"), "test_json")
        XCTAssertEqual(snakeCase.encode("testNumbers123"), "test_numbers123")
    }
}
