@testable
import Alchemy
import AlchemyTesting
import AsyncHTTPClient

struct ClientErrorTests {
    @Test func description() async throws {
        let request = Client.Request(
            url: "http://localhost/foo",
            method: .post,
            headers: [.accept: "bar"],
            body: "foo"
        )
        
        let error = ClientError(
            message: "foo",
            request: request,
            response: Client.Response(
                request: request,
                host: "alchemy",
                status: .conflict,
                headers: [
                    .accept: "bar"
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
                Accept: bar
            ]
            Body: foo

            *** Response ***
            Status: 409 Conflict
            Headers: [
                Accept: bar
            ]
            Body: bar
            """

        #expect(error.description == expectedOutput)
    }
}
