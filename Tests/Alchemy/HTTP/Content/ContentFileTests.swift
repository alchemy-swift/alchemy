@testable
import Alchemy
import AlchemyTest

final class ContentFileTests: XCTestCase {
    func testMultipart() throws {
        let content: Content = .string(Fixtures.multipartString, type: .multipart(boundary: Fixtures.multipartBoundary))
        XCTAssertEqual(try content.files().count, 2)
        XCTAssertNil(try content.file("foo"))
        XCTAssertNil(try content.file("text"))
        let file1 = try content.file("file1")
        XCTAssertNotNil(file1)
        XCTAssertEqual(file1?.contents.string(), "Content of a.txt.\r\n")
        XCTAssertEqual(file1?.name, "a.txt")
        let file2 = try content.file("file2")
        XCTAssertNotNil(file2)
        XCTAssertEqual(file2?.name, "a.html")
        XCTAssertEqual(file2?.contents.string(), "<!DOCTYPE html><title>Content of a.html.</title>\r\n")
    }
}

private struct Fixtures {
    static let multipartBoundary = "---------------------------9051914041544843365972754266"
    static let multipartString = """
        
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="text"\r
        \r
        text default\r
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="file1"; filename="a.txt"\r
        Content-Type: text/plain\r
        \r
        Content of a.txt.\r
        \r
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="file2"; filename="a.html"\r
        Content-Type: text/html\r
        \r
        <!DOCTYPE html><title>Content of a.html.</title>\r
        \r
        -----------------------------9051914041544843365972754266--\r
        
        """
}
