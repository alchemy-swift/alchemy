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
        XCTAssertEqual(Request.fixture(uri: "/path").queryItems, nil)
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
        XCTAssertEqual(try request.parameter("foo"), "one")
        XCTAssertEqual(try request.parameter("bar"), "two")
        XCTAssertEqual(try request.parameter("baz"), "three")
        XCTAssertThrowsError(try request.parameter("fake", as: String.self))
        XCTAssertThrowsError(try request.parameter("foo", as: Int.self))
        XCTAssertTrue(request.parameters.contains(Parameter(key: "foo", value: "one")))
    }
    
    func testBody() {
        XCTAssertNil(Request.fixture(body: nil).body)
        XCTAssertNotNil(Request.fixture(body: .empty).body)
    }
    
    func testDecodeBodyJSON() {
        struct ExpectedJSON: Codable, Equatable {
            var foo = "bar"
        }
        
        XCTAssertThrowsError(try Request.fixture(body: nil).decode(ExpectedJSON.self))
        XCTAssertThrowsError(try Request.fixture(body: .empty).decode(ExpectedJSON.self))
        XCTAssertEqual(try Request.fixture(body: .json).decode(), ExpectedJSON())
    }
}

extension ByteContent {
    fileprivate static var empty: ByteContent {
        .buffer(ByteBuffer())
    }
    
    fileprivate static var json: ByteContent {
        .string("""
            {"foo":"bar"}
            """)
    }
}
