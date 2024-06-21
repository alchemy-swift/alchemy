import AlchemyTest

final class ControllerTests: TestCase<TestApp> {
    func testController() async throws {
        try await Test.get("/test").assertNotFound()
        app.use(TestController())
        try await Test.get("/test").assertOk()
    }
    
    func testControllerMiddleware() async throws {
        var expect = Expect()
        let controller = MiddlewareController(middlewares: [
            ActionMiddleware { expect.signalOne() },
            ActionMiddleware { expect.signalTwo() },
            ActionMiddleware { expect.signalThree() }
        ])
        app.use(controller)
        try await Test.get("/middleware").assertOk()
        
        AssertTrue(expect.one)
        AssertTrue(expect.two)
        AssertTrue(expect.three)
    }
    
    func testControllerMiddlewareRemoved() async throws {
        var expect = Expect()
        let controller = MiddlewareController(middlewares: [
            ActionMiddleware { expect.signalOne() },
            ActionMiddleware { expect.signalTwo() },
            ActionMiddleware { expect.signalThree() },
        ])
        
        app
            .use(controller)
            .get("/outside") { _ async -> String in
                expect.signalFour()
                return "foo"
            }
        
        try await Test.get("/outside").assertOk()
        AssertFalse(expect.one)
        AssertFalse(expect.two)
        AssertFalse(expect.three)
        AssertTrue(expect.four)
    }
}

struct ActionMiddleware: Middleware {
    let action: () async -> Void
    
    func handle(_ request: Request, next: Next) async throws -> Response {
        await action()
        return try await next(request)
    }
}

struct MiddlewareController: Controller {
    let middlewares: [Middleware]
    
    func route(_ router: Router) {
        router
            .use(middlewares)
            .get("/middleware") { _ in
                "Hello, world!"
            }
    }
}

struct TestController: Controller {
    func route(_ router: Router) {
        router.get("/test") { req -> String in
            return "Hello, world!"
        }
    }
}
