import AlchemyTesting

@Suite(.mockContainer)
struct ApplicationErrorRouteTests: TestSuite {
    @Test func customNotFound() async throws {
        try await Test.get("/not_found")
            .assertBody("404 Not Found")
            .assertNotFound()

        App.notFoundHandler { _ in
            "Hello, world!"
        }

        try await Test.get("/not_found")
            .assertBody("Hello, world!")
            .assertOk()
    }
    
    @Test func customInternalError() async throws {
        App.get("/error") { _ -> String in
            throw TestError()
        }

        try await Test.get("/error")
            .assertStatus(.internalServerError)
            .assertBody("500 Internal Server Error")

        App.errorHandler { _, _ in "Nothing to see here." }

        try await Test.get("/error")
            .assertBody("Nothing to see here.")
            .assertOk()
    }
    
    @Test func customInternalErrorThrows() async throws {
        App.errorHandler { _, _ in
            throw TestError()
        }

        App.get("/error") { _ -> String in
            throw TestError()
        }

        try await Test.get("/error")
            .assertBody("500 Internal Server Error")
            .assertStatus(.internalServerError)
    }
}

private struct TestError: Error {
    //
}
