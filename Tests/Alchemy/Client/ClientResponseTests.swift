@testable
import Alchemy
import AlchemyTest
import AsyncHTTPClient

final class ClientResponseTests: XCTestCase {
    func testStatusCodes() {
        XCTAssertTrue(Client.Response(.ok).isOk)
        XCTAssertTrue(Client.Response(.created).isSuccessful)
        XCTAssertTrue(Client.Response(.badRequest).isClientError)
        XCTAssertTrue(Client.Response(.badGateway).isServerError)
        XCTAssertTrue(Client.Response(.internalServerError).isFailed)
        XCTAssertThrowsError(try Client.Response(.internalServerError).validateSuccessful())
        XCTAssertNoThrow(try Client.Response(.ok).validateSuccessful())
    }
    
    func testHeaders() {
        let headers: HTTPHeaders = ["foo":"bar"]
        XCTAssertEqual(Client.Response(headers: headers).headers, headers)
        XCTAssertEqual(Client.Response(headers: headers).header("foo"), "bar")
        XCTAssertEqual(Client.Response(headers: headers).header("baz"), nil)
    }
    
    func testBody() {
        struct SampleJson: Codable, Equatable {
            var foo: String = "bar"
        }
        
        let jsonString = """
        {"foo":"bar"}
        """
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        let body = Bytes.string(jsonString)
        XCTAssertEqual(Client.Response(body: body).body?.buffer, body.buffer)
        XCTAssertEqual(Client.Response(body: body).data, jsonData)
        XCTAssertEqual(Client.Response(body: body).string, jsonString)
        XCTAssertEqual(try Client.Response(body: body).decode(), SampleJson())
        XCTAssertThrowsError(try Client.Response().decode(SampleJson.self))
        XCTAssertThrowsError(try Client.Response(body: body).decode(String.self))
    }
}

extension Client.Response {
    fileprivate init(_ status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], body: Bytes? = nil) {
        self.init(request: Client.Request(url: ""), host: "https://example.com", status: status, version: .http1_1, headers: headers, body: body)
    }
}
