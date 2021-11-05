@testable
import Alchemy
import XCTest

final class RequestUtilitiesTests: XCTestCase {
    func testPath() {
        XCTAssertEqual(Request.fixture(uri: "/foo/bar").path, "/foo/bar")
    }
    
    func testInvalidPath() {
        XCTAssertEqual(Request.fixture(uri: "%").path, "")
    }
    
    func testQueryItems() {
        XCTAssertEqual(Request.fixture(uri: "/path").queryItems, [])
        XCTAssertEqual(Request.fixture(uri: "/path?foo=1&bar=2").queryItems, [
            URLQueryItem(name: "foo", value: "1"),
            URLQueryItem(name: "bar", value: "2")
        ])
    }
    
    func testParameter() {
        let request = Request.fixture()
        request.parameters = [
            Parameter(key: "foo", value: "one"),
            Parameter(key: "bar", value: "two"),
            Parameter(key: "baz", value: "three"),
        ]
        XCTAssertEqual(request.parameter("foo"), "one")
        XCTAssertEqual(request.parameter("bar"), "two")
        XCTAssertEqual(request.parameter("baz"), "three")
        XCTAssertEqual(request.parameter("foo"), Parameter(key: "foo", value: "one"))
    }
    
    func testBody() {
        XCTAssertNil(Request.fixture(body: nil).body)
        XCTAssertNotNil(Request.fixture(body: ByteBuffer()).body)
    }
    
    func testDecodeBodyDict() {
        XCTAssertNil(try Request.fixture(body: nil).decodeBodyDict())
        XCTAssertThrowsError(try Request.fixture(body: .empty).decodeBodyDict())
        XCTAssertEqual(try Request.fixture(body: .json).decodeBodyDict() as? [String: String], ["foo": "bar"])
    }
    
    func testDecodeBodyJSON() {
        struct ExpectedJSON: Codable, Equatable {
            var foo = "bar"
        }
        
        XCTAssertThrowsError(try Request.fixture(body: nil).decodeBodyJSON(as: ExpectedJSON.self))
        XCTAssertThrowsError(try Request.fixture(body: .empty).decodeBodyJSON(as: ExpectedJSON.self))
        XCTAssertEqual(try Request.fixture(body: .json).decodeBodyJSON(), ExpectedJSON())
    }
}

extension ByteBuffer {
    static var empty: ByteBuffer {
        ByteBuffer()
    }
    
    static var json: ByteBuffer {
        ByteBuffer(string: """
        {"foo":"bar"}
        """)
    }
}
