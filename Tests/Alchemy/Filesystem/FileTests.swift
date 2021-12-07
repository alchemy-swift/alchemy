@testable
import Alchemy
import AlchemyTest

final class FileTests: XCTestCase {
    func testFile() {
        let file = File(name: "foo.html", size: 10, content: .buffer("<p>foo</p>"))
        XCTAssertEqual(file.extension, "html")
        XCTAssertEqual(file.size, 10)
        XCTAssertEqual(file.contentType, .html)
    }
    
    func testInvalidURL() {
        let file = File(name: "", size: 3, content: .buffer("foo"))
        XCTAssertEqual(file.extension, "")
    }
}
