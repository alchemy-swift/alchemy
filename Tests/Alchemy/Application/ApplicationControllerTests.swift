import AlchemyTest

final class ApplicationControllerTests: TestCase<TestApp> {
    func testController() async throws {
        try await Test.get("/test").assertNotFound()
        app.controller(TestController())
        try await Test.get("/test").assertOk()
    }
}

struct TestController: Controller {
    func route(_ app: Application) {
        app.get("/test") { req -> String in
            return "Hello, world!"
        }
    }
}
