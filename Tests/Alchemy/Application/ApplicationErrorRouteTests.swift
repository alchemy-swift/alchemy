import AlchemyTest

final class ApplicationErrorRouteTests: TestCase<TestApp> {
    func testCustomNotFound() async throws {
        try await Test.get("/not_found").assertBody(HTTPResponseStatus.notFound.reasonPhrase).assertNotFound()
        app.notFoundHandler { _ in
            "Hello, world!"
        }
        
        try await Test.get("/not_found").assertBody("Hello, world!").assertOk()
    }
    
    func testCustomInternalError() async throws {
        struct TestError: Error {}
        
        app.get("/error") { _ -> String in
            throw TestError()
        }
        
        let status = HTTPResponseStatus.internalServerError
        try await Test.get("/error").assertBody(status.reasonPhrase).assertStatus(status)
        
        app.errorHandler { _, _ in
            "Nothing to see here."
        }
        
        try await Test.get("/error").assertBody("Nothing to see here.").assertOk()
    }
    
    func testThrowingCustomInternalError() async throws {
        struct TestError: Error {}
        
        app.get("/error") { _ -> String in
            throw TestError()
        }
        
        app.errorHandler { _, _ in
            throw TestError()
        }
        
        let status = HTTPResponseStatus.internalServerError
        try await Test.get("/error").assertBody(status.reasonPhrase).assertStatus(.internalServerError)
    }
}
