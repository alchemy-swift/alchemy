import AlchemyTest

final class ContentTypeTests: XCTestCase {
    func testFileExtension() {
        XCTAssertEqual(ContentType(fileExtension: ".html"), .html)
    }
    
    func testInvalidFileExtension() {
        XCTAssertEqual(ContentType(fileExtension: ".sc2save"), nil)
    }
    
    func testParameters() {
        let type = ContentType.multipart(boundary: "foo")
        XCTAssertEqual(type.value, "multipart/form-data")
        XCTAssertEqual(type.string, "multipart/form-data; boundary=foo")
    }
    
    func testEquality() {
        let first = ContentType.multipart(boundary: "foo")
        let second = ContentType.multipart(boundary: "bar")
        XCTAssertEqual(first, second)
    }
}
