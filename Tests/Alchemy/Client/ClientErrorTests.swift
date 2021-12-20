@testable
import Alchemy
import AlchemyTest
import AsyncHTTPClient

final class ClientErrorTests: TestCase<TestApp> {
    func testClientError() async throws {
        let url = URLComponents(string: "http://localhost/foo") ?? URLComponents()
        let request = Client.Request(timeout: nil, urlComponents: url, method: .POST, headers: ["foo": "bar"], body: .string("foo"))
        let response = Client.Response(request: request, host: "alchemy", status: .conflict, version: .http1_1, headers: ["foo": "bar"], body: .string("bar"))
        
        let error = ClientError(message: "foo", request: request, response: response)
        AssertEqual(error.description, """
            *** HTTP Client Error ***
            foo
            
            *** Request ***
            URL: POST http://localhost/foo
            Headers: [
                foo
            ]
            Body: <3 bytes>
            
            *** Response ***
            Status: 409 Conflict
            Headers: [
                foo
            ]
            Body: <3 bytes>
            """)
    }
}
