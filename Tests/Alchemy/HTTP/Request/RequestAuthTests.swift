@testable
import Alchemy
import NIOHTTP1
import XCTest

final class RequestAuthTests: XCTestCase {
    private let sampleBase64Credentials = Data("username:password".utf8).base64EncodedString()
    private let sampleToken = UUID().uuidString
    
    func testNoAuth() {
        XCTAssertNil(Request.fixture().basicAuth())
        XCTAssertNil(Request.fixture().bearerAuth())
        XCTAssertNil(Request.fixture().getAuth())
    }
    
    func testUnknownAuth() {
        let request = Request.fixture(headers: ["Authorization": "Foo \(sampleToken)"])
        XCTAssertNil(request.getAuth())
    }
    
    func testBearerAuth() {
        let request = Request.fixture(headers: ["Authorization": "Bearer \(sampleToken)"])
        XCTAssertNil(request.basicAuth())
        XCTAssertNotNil(request.bearerAuth())
        XCTAssertEqual(request.bearerAuth()?.token, sampleToken)
    }
    
    func testBasicAuth() {
        let request = Request.fixture(headers: ["Authorization": "Basic \(sampleBase64Credentials)"])
        XCTAssertNil(request.bearerAuth())
        XCTAssertNotNil(request.basicAuth())
        XCTAssertEqual(request.basicAuth(), Request.Auth.Basic(username: "username", password: "password"))
    }
    
    func testMalformedBasicAuth() {
        let notBase64Encoded = Request.fixture(headers: ["Authorization": "Basic user:pass"])
        XCTAssertNil(notBase64Encoded.basicAuth())
        let empty = Request.fixture(headers: ["Authorization": "Basic "])
        XCTAssertNil(empty.basicAuth())
    }
}
