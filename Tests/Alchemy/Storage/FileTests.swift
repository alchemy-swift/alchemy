@testable
import Alchemy
import AlchemyTest

final class FileTests: XCTestCase {
    func testFile() {
        let file = File(name: "foo.html", contents: "<p>foo</p>")
        XCTAssertEqual(file.extension, "html")
        XCTAssertEqual(file.contentLength, 10)
        XCTAssertEqual(file.contentType, .html)
    }
    
    func testInvalidURL() {
        let file = File(name: "", contents: "foo")
        XCTAssertEqual(file.extension, "")
    }
}
