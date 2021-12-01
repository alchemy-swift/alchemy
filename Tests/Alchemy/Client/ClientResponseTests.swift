@testable
import Alchemy
import AlchemyTest
import AsyncHTTPClient

final class ClientResponseTests: XCTestCase {
    func testStatusCodes() {
        XCTAssertTrue(ClientResponse(response: .with(.ok)).isOk)
        XCTAssertTrue(ClientResponse(response: .with(.created)).isSuccessful)
        XCTAssertTrue(ClientResponse(response: .with(.badRequest)).isClientError)
        XCTAssertTrue(ClientResponse(response: .with(.badGateway)).isServerError)
        XCTAssertTrue(ClientResponse(response: .with(.internalServerError)).isFailed)
        XCTAssertThrowsError(try ClientResponse(response: .with(.internalServerError)).validateSuccessful())
        XCTAssertNoThrow(try ClientResponse(response: .with(.ok)).validateSuccessful())
    }
    
    func testHeaders() {
        let headers: HTTPHeaders = ["foo":"bar"]
        XCTAssertEqual(ClientResponse(response: .with(headers: headers)).headers, headers)
        XCTAssertEqual(ClientResponse(response: .with(headers: headers)).header("foo"), "bar")
        XCTAssertEqual(ClientResponse(response: .with(headers: headers)).header("baz"), nil)
    }
    
    func testBody() {
        struct SampleJson: Codable, Equatable {
            var foo: String = "bar"
        }
        
        let jsonString = """
        {"foo":"bar"}
        """
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        let body = ByteBuffer(string: jsonString)
        XCTAssertEqual(ClientResponse(response: .with(body: body)).content, Content(buffer: body, type: nil))
        XCTAssertEqual(ClientResponse(response: .with(headers: ["content-type": "application/json"], body: body)).content, Content(buffer: body, type: .json))
        XCTAssertEqual(ClientResponse(response: .with(body: body)).bodyData, jsonData)
        XCTAssertEqual(ClientResponse(response: .with(body: body)).bodyString, jsonString)
        XCTAssertEqual(try ClientResponse(response: .with(body: body)).decodeJSON(), SampleJson())
        XCTAssertThrowsError(try ClientResponse(response: .with()).decodeJSON(SampleJson.self))
        XCTAssertThrowsError(try ClientResponse(response: .with(body: body)).decodeJSON(String.self))
    }
}

extension ClientResponse {
    init(response: HTTPClient.Response) {
        self.init(request: .default, response: response)
    }
}

extension HTTPClient.Request {
    fileprivate static var `default`: HTTPClient.Request {
        try! HTTPClient.Request(url: "https://example.com")
    }
}

extension HTTPClient.Response {
    fileprivate static func with(_ status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], body: ByteBuffer? = nil) -> HTTPClient.Response {
        HTTPClient.Response(host: "https://example.com", status: status, version: .http1_1, headers: headers, body: body)
    }
}
