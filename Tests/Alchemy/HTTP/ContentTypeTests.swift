import AlchemyTest

final class ContentTypeTests: XCTestCase {
    func testFileExtension() {
        XCTAssertEqual(ContentType(fileExtension: ".html"), .html)
    }
    
    func testInvalidFileExtension() {
        XCTAssertEqual(ContentType(fileExtension: ".sc2save"), nil)
    }
}
