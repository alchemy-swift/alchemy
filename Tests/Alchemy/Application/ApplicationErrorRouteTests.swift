import AlchemyTest

final class ApplicationErrorRouteTests: TestCase<TestApp> {
    func testCustomNotFound() async throws {
        try await get("/not_found").assertBody(HTTPResponseStatus.notFound.reasonPhrase).assertNotFound()
        app.notFound { _ in
            "Hello, world!"
        }
        
        try await get("/not_found").assertBody("Hello, world!").assertOk()
    }
    
    func testCustomInternalError() async throws {
        struct TestError: Error {}
        
        app.get("/error") { _ -> String in
            throw TestError()
        }
        
        let status = HTTPResponseStatus.internalServerError
        try await get("/error").assertBody(status.reasonPhrase).assertStatus(status)
        
        app.internalError { _, _ in
            "Nothing to see here."
        }
        
        try await get("/error").assertBody("Nothing to see here.").assertOk()
    }
    
    func testThrowingCustomInternalError() async throws {
        struct TestError: Error {}
        
        app.get("/error") { _ -> String in
            throw TestError()
        }
        
        app.internalError { _, _ in
            throw TestError()
        }
        
        let status = HTTPResponseStatus.internalServerError
        try await get("/error").assertBody(status.reasonPhrase).assertStatus(.internalServerError)
    }
}
