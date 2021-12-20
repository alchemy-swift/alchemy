@testable
import Alchemy
import AlchemyTest
import MultipartKit

final class ResponseTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        FormDataEncoder.boundary = { Fixtures.multipartBoundary }
    }
    
    func testInit() throws {
        Response(status: .created, headers: ["foo": "1", "bar": "2"])
            .assertHeader("foo", value: "1")
            .assertHeader("bar", value: "2")
            .assertHeader("Content-Length", value: "0")
            .assertCreated()
    }
    
    func testInitContentLength() {
        Response(status: .ok)
            .withString("foo")
            .assertHeader("Content-Length", value: "3")
            .assertBody("foo")
            .assertOk()
    }
    
    func testJSONEncode() throws {
        let res = try Response().withValue(Fixtures.object, encoder: .json)
        XCTAssertEqual(res.headers.contentType, .json)
        XCTAssertEqual(res.body?.string(), Fixtures.jsonString)
    }
    
    func testJSONDecode() throws {
        let res = Response().withString(Fixtures.jsonString, type: .json)
        XCTAssertEqual(try res.decode(), Fixtures.object)
    }
    
    func testURLEncode() throws {
        let res = try Response().withValue(Fixtures.object, encoder: .urlForm)
        XCTAssertEqual(res.headers.contentType, .urlForm)
        XCTAssertTrue(res.body?.string() == Fixtures.urlString || res.body?.string() == Fixtures.urlStringAlternate)
    }
    
    func testURLDecode() throws {
        let res = Response().withString(Fixtures.urlString, type: .urlForm)
        XCTAssertEqual(try res.decode(), Fixtures.object)
    }
    
    func testMultipartEncode() throws {
        let res = try Response().withValue(Fixtures.object, encoder: .multipart)
        XCTAssertEqual(res.headers.contentType, .multipart(boundary: Fixtures.multipartBoundary))
        XCTAssertEqual(res.body?.string(), Fixtures.multipartString)
    }
    
    func testMultipartDecode() throws {
        let res = Response().withString(Fixtures.multipartString, type: .multipart(boundary: Fixtures.multipartBoundary))
        XCTAssertEqual(try res.decode(), Fixtures.object)
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
