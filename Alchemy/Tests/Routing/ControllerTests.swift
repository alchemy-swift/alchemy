import AlchemyTesting

final class ControllerTests: TestCase<TestApp> {
    func testController() async throws {
        try await Test.get("/test").assertNotFound()
        app.use(TestController())
        try await Test.get("/test").assertOk()
    }
    
    func testControllerMiddleware() async throws {
        var (one, two, three) = (false, false, false)
        let controller = MiddlewareController(middlewares: [
            ActionMiddleware { one = true },
            ActionMiddleware { two = true },
            ActionMiddleware { three = true }
        ])
        app.use(controller)
        try await Test.get("/middleware").assertOk()
        
        AssertTrue(one)
        AssertTrue(two)
        AssertTrue(three)
    }
    
    func testControllerMiddlewareRemoved() async throws {
        var (one, two, three, four) = (false, false, false, false)
        let controller = MiddlewareController(middlewares: [
            ActionMiddleware { one = true },
            ActionMiddleware { two = true },
            ActionMiddleware { three = true },
        ])
        
        app
            .use(controller)
            .get("/outside") { _ async -> String in
                four = true
                return "foo"
            }
        
        try await Test.get("/outside").assertOk()
        AssertFalse(one)
        AssertFalse(two)
        AssertFalse(three)
        AssertTrue(four)
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
