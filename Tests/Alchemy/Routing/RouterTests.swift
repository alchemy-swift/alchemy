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
        
        try await get("/string").assertBody("one").assertOk()
        try await post("/string").assertBody("two").assertOk()
        try await put("/string").assertBody("three").assertOk()
        try await patch("/string").assertBody("four").assertOk()
        try await delete("/string").assertBody("five").assertOk()
        try await options("/string").assertBody("six").assertOk()
        try await head("/string").assertBody("seven").assertOk()
    }
    
    func testVoidHandlers() async throws {
        app.get("/void") { _ in }
        app.post("/void") { _ in }
        app.put("/void") { _ in }
        app.patch("/void") { _ in }
        app.delete("/void") { _ in }
        app.options("/void") { _ in }
        app.head("/void") { _ in }
        
        try await get("/void").assertEmpty().assertOk()
        try await post("/void").assertEmpty().assertOk()
        try await put("/void").assertEmpty().assertOk()
        try await patch("/void").assertEmpty().assertOk()
        try await delete("/void").assertEmpty().assertOk()
        try await options("/void").assertEmpty().assertOk()
        try await head("/void").assertEmpty().assertOk()
    }
    
    func testEncodableHandlers() async throws {
        app.get("/encodable") { _ in 1 }
        app.post("/encodable") { _ in 2 }
        app.put("/encodable") { _ in 3 }
        app.patch("/encodable") { _ in 4 }
        app.delete("/encodable") { _ in 5 }
        app.options("/encodable") { _ in 6 }
        app.head("/encodable") { _ in 7 }
        
        try await get("/encodable").assertBody("1").assertOk()
        try await post("/encodable").assertBody("2").assertOk()
        try await put("/encodable").assertBody("3").assertOk()
        try await patch("/encodable").assertBody("4").assertOk()
        try await delete("/encodable").assertBody("5").assertOk()
        try await options("/encodable").assertBody("6").assertOk()
        try await head("/encodable").assertBody("7").assertOk()
    }
    
    func testMissing() async throws {
        app.get("/foo") { _ in }
        app.post("/bar") { _ in }
        try await post("/foo").assertNotFound()
    }

    func testQueriesIgnored() async throws {
        app.get("/foo") { _ in }
        try await get("/foo?query=1").assertEmpty().assertOk()
    }

    func testPathParametersMatch() async throws {
        let expect = expectation(description: "The handler should be called.")

        let uuidString = UUID().uuidString
        app.get("/v1/some_path/:uuid/:user_id") { request -> ResponseConvertible in
            XCTAssertEqual(request.parameters, [
                Parameter(key: "uuid", value: uuidString),
                Parameter(key: "user_id", value: "123"),
            ])
            expect.fulfill()
            return "foo"
        }
        
        try await get("/v1/some_path/\(uuidString)/123").assertBody("foo").assertOk()
        wait(for: [expect], timeout: kMinTimeout)
    }

    func testMultipleRequests() async throws {
        app.get("/foo") { _ in 1 }
        app.get("/foo") { _ in 2 }
        try await get("/foo").assertOk().assertBody("2")
    }

    func testInvalidPath() {
        // What happens if a user registers an invalid path string?
    }

    func testForwardSlashIssues() async throws {
        app.get("noslash") { _ in 1 }
        app.get("wrongslash/") { _ in 2 }
        app.get("//////////manyslash//////////////") { _ in 3 }
        app.get("split/path") { _ in 4 }
        try await get("/noslash").assertOk().assertBody("1")
        try await get("/wrongslash").assertOk().assertBody("2")
        try await get("/manyslash").assertOk().assertBody("3")
        try await get("/splitpath").assertNotFound()
        try await get("/split/path").assertOk().assertBody("4")
    }

    func testGroupedPathPrefix() async throws {
        app
            .grouped("group") { app in
                app
                    .get("/foo") { _ in 1 }
                    .get("/bar") { _ in 2 }
                    .grouped("/nested") { app in
                        app.post("/baz") { _ in 3 }
                    }
                    .post("/bar") { _ in 4 }
            }
            .put("/foo") { _ in 5 }
        
        try await get("/group/foo").assertOk().assertBody("1")
        try await get("/group/bar").assertOk().assertBody("2")
        try await post("/group/nested/baz").assertOk().assertBody("3")
        try await post("/group/bar").assertOk().assertBody("4")
        
        // defined outside group -> still available without group prefix
        try await put("/foo").assertOk().assertBody("5")
        
        // only available under group prefix
        try await get("/bar").assertNotFound()
        try await post("/baz").assertNotFound()
        try await post("/bar").assertNotFound()
        try await get("/foo").assertNotFound()
    }
    
    func testError() async throws {
        app.get("/error") { _ -> Void in throw TestError() }
        let status = HTTPResponseStatus.internalServerError
        try await get("/error").assertStatus(status).assertBody(status.reasonPhrase)
    }
    
    func testErrorHandling() async throws {
        app.get("/error_convert") { _ -> Void in throw TestConvertibleError() }
        app.get("/error_convert_error") { _ -> Void in throw TestThrowingConvertibleError() }
        
        let errorStatus = HTTPResponseStatus.internalServerError
        try await get("/error_convert").assertStatus(.badGateway).assertEmpty()
        try await get("/error_convert_error").assertStatus(errorStatus).assertBody(errorStatus.reasonPhrase)
    }
}

private struct TestError: Error {}

private struct TestConvertibleError: Error, ResponseConvertible {
    func response() async throws -> Response {
        Response(status: .badGateway, body: nil)
    }
}

private struct TestThrowingConvertibleError: Error, ResponseConvertible {
    func response() async throws -> Response {
        throw TestError()
    }
}
