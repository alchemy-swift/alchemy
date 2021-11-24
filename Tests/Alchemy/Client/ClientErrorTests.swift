@testable
import Alchemy
import AlchemyTest
import AsyncHTTPClient

final class ClientErrorTests: TestCase<TestApp> {
    func testClientError() async throws {
        let reqBody = HTTPClient.Body.string("foo")
        let request = try HTTPClient.Request(url: "http://localhost/foo", method: .POST, headers: ["foo": "bar"], body: reqBody)
        
        let resBody = ByteBuffer(string: "foo")
        let response = HTTPClient.Response(host: "alchemy", status: .conflict, version: .http1_1, headers: ["foo": "bar"], body: resBody)
        
        let error = ClientError(message: "foo", request: request, response: response)
        AssertEqual(try await error.debugString(), """
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
            Body: foo
            """)
    }
}
