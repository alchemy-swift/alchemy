import AlchemyTesting

@Suite(.mockTestApp)
struct ApplicationErrorRouteTests {
    @Test func customNotFound() async throws {
        try await Test.get("/not_found")
            .expectBody("404 Not Found")
            .expectNotFound()

        Main.notFoundHandler { _ in
            "Hello, world!"
        }

        try await Test.get("/not_found")
            .expectBody("Hello, world!")
            .expectOk()
    }
    
    @Test func customInternalError() async throws {
        Main.get("/error") { _ -> String in
            throw TestError()
        }

        try await Test.get("/error")
            .expectStatus(.internalServerError)
            .expectBody("500 Internal Server Error")

        Main.errorHandler { _, _ in "Nothing to see here." }

        try await Test.get("/error")
            .expectBody("Nothing to see here.")
            .expectOk()
    }
    
    @Test func customInternalErrorThrows() async throws {
        Main.errorHandler { _, _ in
            throw TestError()
        }

        Main.get("/error") { _ -> String in
            throw TestError()
        }

        try await Test.get("/error")
            .expectBody("500 Internal Server Error")
            .expectStatus(.internalServerError)
    }
}

private struct TestError: Error {
    //
}
