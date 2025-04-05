import AlchemyTesting

@Suite(.serialized)
struct ApplicationErrorRouteTests: AppSuite {
    let app = TestApp()

    @Test func customNotFound() async throws {
        try await withApp { app in
            try await Test.get("/not_found")
                .assertBody("404 Not Found")
                .assertNotFound()

            app.notFoundHandler { _ in
                "Hello, world!"
            }

            try await Test.get("/not_found")
                .assertBody("Hello, world!")
                .assertOk()
        }
    }
    
    @Test func customInternalError() async throws {
        try await withApp { app in
            app.get("/error") { _ -> String in
                throw TestError()
            }

            try await Test.get("/error")
                .assertStatus(.internalServerError)
                .assertBody("500 Internal Server Error")

            app.errorHandler { _, _ in "Nothing to see here." }

            try await Test.get("/error")
                .assertBody("Nothing to see here.")
                .assertOk()
        }
    }
    
    @Test func customInternalErrorThrows() async throws {
        try await withApp { app in
            app.errorHandler { _, _ in
                throw TestError()
            }

            app.get("/error") { _ -> String in
                throw TestError()
            }

            try await Test.get("/error")
                .assertBody("500 Internal Server Error")
                .assertStatus(.internalServerError)
        }
    }
}

private struct TestError: Error {
    //
}
