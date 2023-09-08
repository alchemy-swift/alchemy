@testable
import Alchemy
import AlchemyTest
import AsyncHTTPClient

final class ClientErrorTests: TestCase<TestApp> {
    func testClientError() async throws {
        let request = Client.Request(
            url: "http://localhost/foo",
            method: .POST,
            headers: ["foo": "bar"],
            body: "foo"
        )
        
        let error = ClientError(
            message: "foo",
            request: request,
            response: Client.Response(
                request: request,
                host: "alchemy",
                status: .conflict,
                version: .http1_1,
                headers: [
                    "foo": "bar"
                ],
                body: "bar"
            )
        )

        let expectedOutput = """
            *** HTTP Client Error ***
            foo

            *** Request ***
            URL: POST http://localhost/foo
            Headers: [
                foo: bar
            ]
            Body: foo

            *** Response ***
            Status: 409 Conflict
            Headers: [
                foo: bar
            ]
            Body: bar
            """

        AssertEqual(error.description, expectedOutput)
    }
}
