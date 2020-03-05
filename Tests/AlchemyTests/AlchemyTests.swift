import XCTest
@testable import Alchemy

final class AlchemyTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Alchemy().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
