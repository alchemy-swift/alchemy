import AlchemyTest
import Papyrus

final class PapyrusRoutingTests: TestCase<TestApp> {
    private let api = TestAPI()
    
    func testTypedReqTypedRes() async throws {
        app.on(api.createTest) { request, content in
            return "foo"
        }
        
        let res = try await Test.post("/test")
        res.assertSuccessful()
        res.assertJson("foo")
    }
    
    func testEmptyReqTypedRes() async throws {
        app.on(api.getTest) { request in
            return "foo"
        }
        
        let res = try await Test.get("/test")
        res.assertSuccessful()
        res.assertJson("foo")
    }
    
    func testTypedReqEmptyRes() async throws {
        app.on(api.updateTests) { request, content in
            return
        }
        
        let res = try await Test.patch("/test")
        res.assertSuccessful()
        res.assertEmpty()
    }
    
    func testEmptyReqEmptyRes() async throws {
        app.on(api.deleteTests) { request in
            return
        }
        
        let res = try await Test.delete("/test")
        res.assertSuccessful()
        res.assertEmpty()
    }
}

private final class TestAPI: API {
    @POST("/test")   var createTest = Endpoint<CreateTestReq, String>()
    @GET("/test")    var getTest = Endpoint<Empty, String>()
    @PATCH("/test")  var updateTests = Endpoint<UpdateTestsReq, Empty>()
    @DELETE("/test") var deleteTests = Endpoint<Empty, Empty>()
}

private struct CreateTestReq: EndpointRequest {}
private struct UpdateTestsReq: EndpointRequest {}
