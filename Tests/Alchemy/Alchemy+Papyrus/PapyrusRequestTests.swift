import AlchemyTest

final class PapyrusRequestTests: TestCase<TestApp> {
    let api = SampleAPI()
    
    func testRequest() async throws {
        Http.stub()
        _ = try await api.createTest.request(SampleAPI.CreateTestReq(foo: "one", bar: "two", baz: "three"))
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
        _ = try await api.urlEncode.request(SampleAPI.UrlEncodeReq())
        Http.assertSent(1) {
            $0.hasMethod(.PUT) &&
            $0.hasPath("/url") &&
            $0.hasBody(string: "foo=one")
        }
    }
}

final class SampleAPI: EndpointGroup {
    var baseURL: String = "http://localhost:3000"
    
    @POST("/create")
    var createTest: Endpoint<CreateTestReq, Empty>
    struct CreateTestReq: RequestComponents {
        @Papyrus.Header var foo: String
        @Papyrus.Header var bar: String
        @URLQuery var baz: String
    }
    
    @GET("/get")
    var getTest: Endpoint<Empty, String>
    
    @PUT("/url")
    var urlEncode: Endpoint<UrlEncodeReq, Empty>
    struct UrlEncodeReq: RequestComponents {
        static var contentEncoding: ContentEncoding = .url
        
        struct Content: Codable {
            var foo = "one"
        }
        
        @Body var body = Content()
    }
}
