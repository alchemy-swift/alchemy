import AlchemyTest
import Papyrus

final class PapyrusRequestTests: TestCase<TestApp> {
    private let api = Provider(api: SampleAPI(baseURL: "http://localhost:3000"))
    
    func testRequest() async throws {
        Http.stub()
        _ = try await api.createTest.request(CreateTestReq(foo: "one", bar: "two", baz: "three"))
        Http.assertSent {
            $0.hasMethod(.POST) &&
            $0.hasPath("/create") &&
            $0.hasHeader("foo", value: "one") &&
            $0.hasHeader("bar", value: "two") &&
            $0.hasQuery("baz", value: "three")
        }
    }
    
    func testResponse() async throws {
        Http.stub([
            "localhost:3000/get": .stub(body: "\"testing\"")
        ])
        let response = try await api.getTest.request().response
        XCTAssertEqual(response, "testing")
        Http.assertSent(1) {
            $0.hasMethod(.GET) &&
            $0.hasPath("/get")
        }
    }
    
    func testUrlEncode() async throws {
        Http.stub()
        _ = try await api.urlEncode.request(UrlEncodeReq())
        Http.assertSent(1) {
            print($0.body?.string() ?? "N/A")
            return $0.hasMethod(.PUT) &&
            $0.hasPath("/url")// &&
//            $0.hasBody(string: "foo=one")
        }
    }
}

private struct SampleAPI: API {
    let baseURL: String
    
    @POST("/create")
    var createTest = Endpoint<CreateTestReq, Empty>()
    
    @GET("/get")
    var getTest = Endpoint<Empty, String>()
    
    @URLForm
    @PUT("/url")
    var urlEncode = Endpoint<UrlEncodeReq, Empty>()
}

private struct CreateTestReq: EndpointRequest {
    @Header var foo: String
    @Header var bar: String
    @RequestQuery var baz: String
}

private struct UrlEncodeReq: EndpointRequest {
    struct Content: Codable {
        var foo = "one"
    }
    
    @Body var body = Content()
}

extension String: EndpointResponse {}
