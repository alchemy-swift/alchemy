@testable
import Alchemy
import AlchemyTest

let kMinTimeout: TimeInterval = 0.01

final class RouterTests: TestCase<TestApp> {
    func testResponseConvertibleHandlers() async throws {
        app.get("/string") { _ in "one" }
        app.post("/string") { _ in "two" }
        app.put("/string") { _ in "three" }
        app.patch("/string") { _ in "four" }
        app.delete("/string") { _ in "five" }
        app.options("/string") { _ in "six" }
        app.head("/string") { _ in "seven" }
        
        try await Test.get("/string").assertBody("one").assertOk()
        try await Test.post("/string").assertBody("two").assertOk()
        try await Test.put("/string").assertBody("three").assertOk()
        try await Test.patch("/string").assertBody("four").assertOk()
        try await Test.delete("/string").assertBody("five").assertOk()
        try await Test.options("/string").assertBody("six").assertOk()
        try await Test.head("/string").assertBody("seven").assertOk()
    }
    
    func testVoidHandlers() async throws {
        app.get("/void") { _ in }
        app.post("/void") { _ in }
        app.put("/void") { _ in }
        app.patch("/void") { _ in }
        app.delete("/void") { _ in }
        app.options("/void") { _ in }
        app.head("/void") { _ in }
        
        try await Test.get("/void").assertEmpty().assertOk()
        try await Test.post("/void").assertEmpty().assertOk()
        try await Test.put("/void").assertEmpty().assertOk()
        try await Test.patch("/void").assertEmpty().assertOk()
        try await Test.delete("/void").assertEmpty().assertOk()
        try await Test.options("/void").assertEmpty().assertOk()
        try await Test.head("/void").assertEmpty().assertOk()
    }
    
    func testEncodableHandlers() async throws {
        app.get("/encodable") { _ in 1 }
        app.post("/encodable") { _ in 2 }
        app.put("/encodable") { _ in 3 }
        app.patch("/encodable") { _ in 4 }
        app.delete("/encodable") { _ in 5 }
        app.options("/encodable") { _ in 6 }
        app.head("/encodable") { _ in 7 }
        
        try await Test.get("/encodable").assertBody("1").assertOk()
        try await Test.post("/encodable").assertBody("2").assertOk()
        try await Test.put("/encodable").assertBody("3").assertOk()
        try await Test.patch("/encodable").assertBody("4").assertOk()
        try await Test.delete("/encodable").assertBody("5").assertOk()
        try await Test.options("/encodable").assertBody("6").assertOk()
        try await Test.head("/encodable").assertBody("7").assertOk()
    }
    
    func testMissing() async throws {
        app.get("/foo") { _ in }
        app.post("/bar") { _ in }
        try await Test.post("/foo").assertNotFound()
    }

    func testQueriesIgnored() async throws {
        app.get("/foo") { _ in }
        try await Test.get("/foo?query=1").assertEmpty().assertOk()
    }

    func testPathParametersMatch() async throws {
        var expect = Expect()
        let uuidString = UUID().uuidString
        app.get("/v1/some_path/:uuid/:user_id") {
            XCTAssertEqual($0.parameters, [
                Request.Parameter(key: "uuid", value: uuidString),
                Request.Parameter(key: "user_id", value: "123"),
            ])
            expect.signalOne()
            return "foo"
        }
        
        try await Test.get("/v1/some_path/\(uuidString)/123").assertBody("foo").assertOk()
        AssertTrue(expect.one)
    }

    func testMultipleRequests() async throws {
        app.get("/foo") { _ in 1 }
        app.get("/foo") { _ in 2 }
        try await Test.get("/foo").assertOk().assertBody("1")
    }

    func testInvalidPath() throws {
        throw XCTSkip()
    }

    func testForwardSlashIssues() async throws {
        app.get("noslash") { _ in 1 }
        app.get("wrongslash/") { _ in 2 }
        app.get("//////////manyslash//////////////") { _ in 3 }
        app.get("split/path") { _ in 4 }
        try await Test.get("/noslash").assertOk().assertBody("1")
        try await Test.get("/wrongslash").assertOk().assertBody("2")
        try await Test.get("/manyslash").assertOk().assertBody("3")
        try await Test.get("/splitpath").assertNotFound()
        try await Test.get("/split/path").assertOk().assertBody("4")
    }

    func testGroupedPathPrefix() async throws {
        app
            .grouping("group") { app in
                app
                    .get("/foo") { _ in 1 }
                    .get("/bar") { _ in 2 }
                    .grouping("/nested") { app in
                        app.post("/baz") { _ in 3 }
                    }
                    .post("/bar") { _ in 4 }
            }
            .put("/foo") { _ in 5 }
        
        try await Test.get("/group/foo").assertOk().assertBody("1")
        try await Test.get("/group/bar").assertOk().assertBody("2")
        try await Test.post("/group/nested/baz").assertOk().assertBody("3")
        try await Test.post("/group/bar").assertOk().assertBody("4")
        
        // defined outside group -> still available without group prefix
        try await Test.put("/foo").assertOk().assertBody("5")
        
        // only available under group prefix
        try await Test.get("/bar").assertNotFound()
        try await Test.post("/baz").assertNotFound()
        try await Test.post("/bar").assertNotFound()
        try await Test.get("/foo").assertNotFound()
    }
    
    func testError() async throws {
        app.get("/error") { _ -> Void in throw TestError() }
        let status = HTTPResponseStatus.internalServerError
        try await Test.get("/error").assertStatus(status).assertEmpty()
    }
    
    func testErrorHandling() async throws {
        app.get("/error_convert") { _ -> Void in throw TestConvertibleError() }
        app.get("/error_convert_error") { _ -> Void in throw TestThrowingConvertibleError() }
        
        let errorStatus = HTTPResponseStatus.internalServerError
        try await Test.get("/error_convert").assertStatus(.badGateway).assertEmpty()
        try await Test.get("/error_convert_error").assertStatus(errorStatus).assertEmpty()
    }
}

private struct TestError: Error {}

private struct TestConvertibleError: Error, ResponseConvertible {
    func response() async throws -> Response {
        Response(status: .badGateway)
    }
}

private struct TestThrowingConvertibleError: Error, ResponseConvertible {
    func response() async throws -> Response {
        throw TestError()
    }
}
