@testable
import Alchemy
import AlchemyTest

final class FileTests: XCTestCase {
    func testFile() {
        let file = File(name: "foo.html", source: .raw, content: .buffer("<p>foo</p>"), size: 10)
        XCTAssertEqual(file.extension, "html")
        XCTAssertEqual(file.size, 10)
        XCTAssertEqual(file.contentType, .html)
    }
    
    func testInvalidURL() {
        let file = File(name: "", source: .raw, content: .buffer("foo"), size: 3)
        XCTAssertEqual(file.extension, "")
    }
}
