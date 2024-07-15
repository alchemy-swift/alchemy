@testable
import Alchemy
import XCTest

final class RequestTests: XCTestCase {
    private let sampleBase64Credentials = Data("username:password".utf8).base64EncodedString()
    private let sampleToken = UUID().uuidString
    
    func testPath() {
        XCTAssertEqual(Request.fake(uri: "/foo/bar").path, "/foo/bar")
    }
    
    func testQueryItems() {
        XCTAssertEqual(Request.fake(uri: "/path").queryItems, nil)
        XCTAssertEqual(Request.fake(uri: "/path?foo=1&bar=2").queryItems, [
            URLQueryItem(name: "foo", value: "1"),
            URLQueryItem(name: "bar", value: "2")
        ])
    }
    
    func testParameter() {
        let request = Request.fake()
        request.parameters = [
            Request.Parameter(key: "foo", value: "one"),
            Request.Parameter(key: "bar", value: "two"),
            Request.Parameter(key: "baz", value: "three"),
        ]
        XCTAssertEqual(request.parameter("foo"), "one")
        XCTAssertEqual(request.parameter("bar"), "two")
        XCTAssertEqual(request.parameter("baz"), "three")
        XCTAssertNil(request.parameter("fake", as: String.self))
        XCTAssertNil(request.parameter("foo", as: Int.self))
        XCTAssertTrue(request.parameters.contains(Request.Parameter(key: "foo", value: "one")))
    }
    
    func testBody() {
        XCTAssertNil(Request.fake(body: nil).body)
        XCTAssertNotNil(Request.fake(body: .empty).body)
    }
    
    func testDecodeBodyJSON() {
        struct ExpectedJSON: Codable, Equatable {
            var foo = "bar"
        }
        
        XCTAssertThrowsError(try Request.fake(body: nil).decode(ExpectedJSON.self))
        XCTAssertThrowsError(try Request.fake(body: .empty).decode(ExpectedJSON.self))
        XCTAssertEqual(try Request.fake(body: .json).decode(), ExpectedJSON())
    }

    // MARK: Parameters

    func testStringConversion() {
        XCTAssertEqual(Request.Parameter(key: "foo", value: "bar").string(), "bar")
    }

    func testIntConversion() throws {
        XCTAssertEqual(try Request.Parameter(key: "foo", value: "1").int(), 1)
        XCTAssertThrowsError(try Request.Parameter(key: "foo", value: "foo").int())
    }

    func testUuidConversion() throws {
        let uuid = UUID()
        XCTAssertEqual(try Request.Parameter(key: "foo", value: uuid.uuidString).uuid(), uuid)
        XCTAssertThrowsError(try Request.Parameter(key: "foo", value: "foo").uuid())
    }

    // MARK: Auth

    func testNoAuth() {
        XCTAssertNil(Request.fake().basicAuth())
        XCTAssertNil(Request.fake().bearerAuth())
        XCTAssertNil(Request.fake().getAuth())
    }

    func testUnknownAuth() {
        let request = Request.fake(headers: [.authorization: "Foo \(sampleToken)"])
        XCTAssertNil(request.getAuth())
    }

    func testBearerAuth() {
        let request = Request.fake(headers: [.authorization: "Bearer \(sampleToken)"])
        XCTAssertNil(request.basicAuth())
        XCTAssertNotNil(request.bearerAuth())
        XCTAssertEqual(request.bearerAuth()?.token, sampleToken)
    }

    func testBasicAuth() {
        let request = Request.fake(headers: [.authorization: "Basic \(sampleBase64Credentials)"])
        XCTAssertNil(request.bearerAuth())
        XCTAssertNotNil(request.basicAuth())
        XCTAssertEqual(request.basicAuth(), Request.Auth.Basic(username: "username", password: "password"))
    }

    func testMalformedBasicAuth() {
        let notBase64Encoded = Request.fake(headers: [.authorization: "Basic user:pass"])
        XCTAssertNil(notBase64Encoded.basicAuth())
        let empty = Request.fake(headers: [.authorization: "Basic "])
        XCTAssertNil(empty.basicAuth())
    }

    // MARK: Associated Values

    func testValue() {
        let request = Request.fake()
        request.set("foo")
        XCTAssertEqual(try request.get(), "foo")
    }

    func testOverwite() {
        let request = Request.fake()
        request.set("foo")
        request.set("bar")
        XCTAssertEqual(try request.get(), "bar")
    }

    func testNoValue() {
        let request = Request.fake()
        request.set(1)
        XCTAssertThrowsError(try request.get(String.self))
    }
}

extension Bytes {
    fileprivate static var empty: Bytes {
        .buffer(ByteBuffer())
    }
    
    fileprivate static var json: Bytes {
        .string("""
            {"foo":"bar"}
            """)
    }
}
