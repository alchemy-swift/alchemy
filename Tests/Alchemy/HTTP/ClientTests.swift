@testable
import Alchemy
import AlchemyTest

final class ClientTests: TestCase<TestApp> {
    func testQueries() async throws {
        Http.stub([
            "localhost/foo": .stub(.unauthorized),
            "localhost/*": .stub(.ok),
            "*": .stub(.ok),
        ])
        try await Http.withQueries(["foo":"bar"]).get("https://localhost/baz")
            .assertOk()
        
        try await Http.withQueries(["bar":"2"]).get("https://localhost/foo?baz=1")
            .assertUnauthorized()
        
        try await Http.get("https://example.com")
            .assertOk()
        
        Http.assertSent { $0.hasQuery("foo", value: "bar") }
        Http.assertSent { $0.hasQuery("bar", value: 2) && $0.hasQuery("baz", value: 1) }
    }

    // MARK: Response

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

    func testStreaming() async throws {
        let streamResponse: Client.Response = .stub(body: .stream {
            try await $0.write("foo")
            try await $0.write("bar")
            try await $0.write("baz")
        })

        Http.stub(["example.com/*": streamResponse])

        var res = try await Http.get("https://example.com/foo")
        try await res.collect()
            .assertOk()
            .assertBody("foobarbaz")
    }
}

extension Client.Response {
    fileprivate init(_ status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], body: Bytes? = nil) {
        self.init(request: Client.Request(url: ""), host: "https://example.com", status: status, version: .http1_1, headers: headers, body: body)
    }
}
