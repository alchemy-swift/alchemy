import AlchemyTesting

@Suite(.mockContainer)
final class ControllerTests: TestSuite {
    @Test func controller() async throws {
        #expect(try await Test.get("/test").status == .notFound)
        App.use(TestController())
        #expect(try await Test.get("/test").status == .ok)
    }

    @Test func controllerMiddleware() async throws {
        var (one, two, three) = (false, false, false)

        App.use(
            MiddlewareController(middlewares: [
                ActionMiddleware { one = true },
                ActionMiddleware { two = true },
                ActionMiddleware { three = true }
            ])
        )

        let res = try await Test.get("/middleware")
        #expect(res.status == .ok)
        #expect(one)
        #expect(two)
        #expect(three)
    }
    
    @Test func controllerMiddlewareRemoved() async throws {
        var (one, two, three, four) = (false, false, false, false)
        App
            .use(
                MiddlewareController(middlewares: [
                    ActionMiddleware { one = true },
                    ActionMiddleware { two = true },
                    ActionMiddleware { three = true },
                ])
            )
            .get("/outside") { _ async -> String in
                four = true
                return "foo"
            }
        
        let res = try await Test.get("/outside")
        #expect(res.status == .ok)
        #expect(!one)
        #expect(!two)
        #expect(!three)
        #expect(four)
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
