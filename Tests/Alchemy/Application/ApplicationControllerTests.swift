import AlchemyTest

final class ApplicationControllerTests: TestCase<TestApp> {
    func testController() async throws {
        try await Test.get("/test").assertNotFound()
        app.controller(TestController())
        try await Test.get("/test").assertOk()
    }
    
    func testControllerMiddleware() async throws {
        let expect = Expect()
        let controller = MiddlewareController(middlewares: [
            ActionMiddleware { await expect.signalOne() },
            ActionMiddleware { await expect.signalTwo() },
            ActionMiddleware { await expect.signalThree() }
        ])
        app.controller(controller)
        try await Test.get("/middleware").assertOk()
        
        AssertTrue(await expect.one)
        AssertTrue(await expect.two)
        AssertTrue(await expect.three)
    }
    
    func testControllerMiddlewareRemoved() async throws {
        let expect = Expect()
        let controller = MiddlewareController(middlewares: [
            ActionMiddleware { await expect.signalOne() },
            ActionMiddleware { await expect.signalTwo() },
            ActionMiddleware { await expect.signalThree() },
        ])
        
        app
            .controller(controller)
            .get("/outside") { _ async -> String in
                await expect.signalFour()
                return "foo"
            }
        
        try await Test.get("/outside").assertOk()
        AssertFalse(await expect.one)
        AssertFalse(await expect.two)
        AssertFalse(await expect.three)
        AssertTrue(await expect.four)
    }
}

struct ActionMiddleware: Middleware {
    let action: () async -> Void
    
    func handle(_ request: Request, next: (Request) async throws -> Response) async throws -> Response {
        await action()
        return try await next(request)
    }
}

struct MiddlewareController: Controller {
    let middlewares: [Middleware]
    
    func route(_ app: Application) {
        app
            .use(middlewares)
            .get("/middleware") { _ in
                "Hello, world!"
            }
    }
}

struct TestController: Controller {
    func route(_ app: Application) {
        app.get("/test") { req -> String in
            return "Hello, world!"
        }
    }
}
