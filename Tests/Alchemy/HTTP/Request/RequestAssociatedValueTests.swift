@testable
import Alchemy
import XCTest

final class RequestAssociatedValueTests: XCTestCase {
    func testValue() {
        let request = Request.fixture()
        request.set("foo")
        XCTAssertEqual(try request.get(), "foo")
    }
    
    func testOverwite() {
        let request = Request.fixture()
        request.set("foo")
        request.set("bar")
        XCTAssertEqual(try request.get(), "bar")
    }
    
    func testNoValue() {
        let request = Request.fixture()
        request.set(1)
        XCTAssertThrowsError(try request.get(String.self))
    }
}
