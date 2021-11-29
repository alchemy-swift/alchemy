import NIOHTTP1
import XCTest
@testable import Alchemy

final class RequestDecodingTests: XCTestCase {
    func testRequestDecoding() {
        let request = Request.fixture(uri: "localhost:3000/posts/1?done=true", headers: ["TestHeader":"123"])
        request.parameters = [Parameter(key: "post_id", value: "1")]
        XCTAssertEqual(request.parameter("post_id") as String?, "1")
        XCTAssertEqual(request.query("done"), "true")
        XCTAssertEqual(request.header("TestHeader"), "123")
        
        XCTAssertThrowsError(try request.decodeContent(type: .json) as String)
    }
    
    func testJsonDecoding() throws {
        let headers: HTTPHeaders = ["TestHeader":"123"]
        let head = HTTPRequestHead(version: .http1_1, method: .GET, uri: "localhost:3000/posts/1?key=value", headers: headers)
        let request = Request(head: head, bodyBuffer: ByteBuffer(string: """
            {
                "key": "value"
            }
            """), remoteAddress: nil)
        
        struct JsonSample: Codable, Equatable {
            var key = "value"
        }
        
        XCTAssertEqual(try request.decodeContent(type: .json), JsonSample())
        XCTAssertThrowsError(try request.decodeContent(type: .url) as JsonSample)
    }
}
