@testable
import Alchemy
import AlchemyTesting

final class ClientTests {
    let client = Client()
    deinit { try? client.shutdown() }

    @Test func queries() async throws {
        client.stub([
            "localhost/foo": .stub(.forbidden),
            "localhost/*": .stub(.ok),
            "*": .stub(.ok),
        ])

        let res1 = try await client.builder().withQueries(["foo":"bar"]).get("https://localhost/baz")
        #expect(res1.status == .ok)

        let res2 = try await client.builder().withQueries(["bar":"2"]).get("https://localhost/foo?baz=1")
        #expect(res2.status == .forbidden)

        let res3 = try await client.builder().get("https://example.com")
        #expect(res3.status == .ok)

        client.builder().assertSent { $0.hasQuery("foo", value: "bar") }
        client.builder().assertSent { $0.hasQuery("bar", value: 2) && $0.hasQuery("baz", value: 1) }
    }

    // MARK: Response

    @Test func statusCodes() throws {
        #expect(Client.Response(.ok).isOk)
        #expect(Client.Response(.created).isSuccessful)
        #expect(Client.Response(.badRequest).isClientError)
        #expect(Client.Response(.badGateway).isServerError)
        #expect(Client.Response(.internalServerError).isFailed)
        #expect(throws: Error.self) { try Client.Response(.internalServerError).validateSuccessful() }
        try Client.Response(.ok).validateSuccessful()
    }

    @Test func headers() {
        let headers: HTTPFields = [.accept:"bar"]
        #expect(Client.Response(headers: headers).headers == headers)
        #expect(Client.Response(headers: headers).header(.accept) == "bar")
        #expect(Client.Response(headers: headers).header(.age) == nil)
    }

    @Test func body() throws {
        struct SampleJson: Codable, Equatable {
            var foo: String = "bar"
        }

        let jsonString = """
        {"foo":"bar"}
        """
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        let body = Bytes.string(jsonString)
        #expect(Client.Response(body: body).body?.buffer == body.buffer)
        #expect(Client.Response(body: body).data == jsonData)
        #expect(Client.Response(body: body).string == jsonString)
        #expect(try Client.Response(body: body).decode() == SampleJson())
        #expect(throws: Error.self) { try Client.Response().decode(SampleJson.self) }
        #expect(throws: Error.self) { try Client.Response(body: body).decode(String.self) }
    }

    @Test func streaming() async throws {
        let streamResponse: Client.Response = .stub(body: .stream {
            $0.write(ByteBuffer(string: "foo"))
            $0.write(ByteBuffer(string: "bar"))
            $0.write(ByteBuffer(string: "baz"))
        })

        client.stub(["example.com/*": streamResponse])

        var res = try await client.builder().get("https://example.com/foo")
        res = try await res.collect()
        #expect(res.status == .ok)
        #expect(res.body?.string == "foobarbaz")
    }
}

extension Client.Response {
    fileprivate init(_ status: HTTPResponse.Status = .ok, headers: HTTPFields = [:], body: Bytes? = nil) {
        self.init(request: Client.Request(url: ""), host: "https://example.com", status: status, headers: headers, body: body)
    }
}
