@testable
import Alchemy
import AlchemyTest
import MultipartKit

final class ContentTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        FormDataEncoder.boundary = { Fixtures.multipartBoundary }
    }
    
    func testStringLiteral() throws {
        let content: Content = "foo"
        XCTAssertEqual(content.type, .plainText)
        XCTAssertEqual(content.string(), "foo")
    }
    
    func testJSONEncode() throws {
        let content: Content = try .encodable(Fixtures.object, encoder: .json)
        XCTAssertEqual(content.type, .json)
        XCTAssertEqual(content.string(), Fixtures.jsonString)
    }
    
    func testJSONDecode() throws {
        let content: Content = .string(Fixtures.jsonString, type: .json)
        XCTAssertEqual(try content.decode(), Fixtures.object)
    }
    
    func testURLEncode() throws {
        let content: Content = try .encodable(Fixtures.object, encoder: .url)
        XCTAssertEqual(content.type, .urlEncoded)
        XCTAssertTrue(content.string() == Fixtures.urlString || content.string() == Fixtures.urlStringAlternate)
    }
    
    func testURLDecode() throws {
        let content: Content = .string(Fixtures.urlString, type: .urlEncoded)
        XCTAssertEqual(try content.decode(), Fixtures.object)
    }
    
    func testMultipartEncode() throws {
        let content: Content = try .encodable(Fixtures.object, encoder: .multipart)
        XCTAssertEqual(content.type, .multipart(boundary: Fixtures.multipartBoundary))
        XCTAssertEqual(content.string(), Fixtures.multipartString)
    }
    
    func testMultipartDecode() throws {
        let content: Content = .string(Fixtures.multipartString, type: .multipart(boundary: Fixtures.multipartBoundary))
        XCTAssertEqual(try content.decode(), Fixtures.object)
    }
}

private struct Fixtures {
    struct Test: Codable, Equatable {
        var foo = "foo"
        var bar = "bar"
    }
    
    static let jsonString = """
        {"foo":"foo","bar":"bar"}
        """
    
    static let urlString = "foo=foo&bar=bar"
    static let urlStringAlternate = "bar=bar&foo=foo"
    
    static let multipartBoundary = "foo123"
    
    static let multipartString = """
        --foo123\r
        Content-Disposition: form-data; name=\"foo\"\r
        \r
        foo\r
        --foo123\r
        Content-Disposition: form-data; name=\"bar\"\r
        \r
        bar\r
        --foo123--\r
        
        """
    
    static let object = Test()
}
