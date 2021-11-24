import AlchemyTest

final class ApplicationControllerTests: TestCase<TestApp> {
    func testController() async throws {
        try await get("/test").assertNotFound()
        app.controller(TestController())
        try await get("/test").assertOk()
    }
}

struct TestController: Controller {
    func route(_ app: Application) {
        app.get("/test") { req -> String in
            return "Hello, world!"
        }
    }
}
