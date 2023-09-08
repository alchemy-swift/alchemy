import AlchemyTest

final class ApplicationErrorRouteTests: TestCase<TestApp> {
    func testCustomNotFound() async throws {
        try await Test.get("/not_found")
            .assertEmpty()
            .assertNotFound()
        
        app.notFoundHandler { _ in
            "Hello, world!"
        }
        
        try await Test.get("/not_found")
            .assertBody("Hello, world!")
            .assertOk()
    }
    
    func testCustomInternalError() async throws {
        app.get("/error") { _ -> String in
            throw TestError()
        }
        
        try await Test.get("/error")
            .assertStatus(.internalServerError)
            .assertEmpty()

        app.errorHandler { _, _ in
            "Nothing to see here."
        }
        
        try await Test.get("/error")
            .assertBody("Nothing to see here.")
            .assertOk()
    }
    
    func testThrowingCustomInternalError() async throws {
        app.errorHandler { _, _ in
            throw TestError()
        }

        app.get("/error") { _ -> String in
            throw TestError()
        }
        
        try await Test.get("/error")
            .assertEmpty()
            .assertStatus(.internalServerError)
    }
}

private struct TestError: Error {
    //
}
