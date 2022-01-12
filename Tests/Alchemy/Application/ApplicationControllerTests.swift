import AlchemyTest

final class ApplicationControllerTests: TestCase<TestApp> {
    func testController() async throws {
        try await Test.get("/test").assertNotFound()
        app.controller(TestController())
        try await Test.get("/test").assertOk()
    }
    
    func testControllerMiddleware() async throws {
        actor ExpectActor {
            var middleware1 = false, middleware2 = false, middleware3 = false
            func mw1() async { middleware1 = true }
            func mw2() async { middleware2 = true }
            func mw3() async { middleware3 = true }
        }
        
        let expect = ExpectActor()
        let controller = MiddlewareController(middlewares: [
            ActionMiddleware { await expect.mw1() },
            ActionMiddleware { await expect.mw2() },
            ActionMiddleware { await expect.mw3() }
        ])
        app.controller(controller)
        try await Test.get("/middleware").assertOk()
        
        AssertTrue(await expect.middleware1)
        AssertTrue(await expect.middleware2)
        AssertTrue(await expect.middleware3)
    }
    
    func testControllerMiddlewareRemoved() async throws {
        let exp1 = expectationInverted(description: "")
        let exp2 = expectationInverted(description: "")
        let exp3 = expectationInverted(description: "")
        let controller = MiddlewareController(middlewares: [
            ExpectMiddleware(expectation: exp1),
            ExpectMiddleware(expectation: exp2),
            ExpectMiddleware(expectation: exp3)
        ])
        
        let exp4 = expectation(description: "")
        app
            .controller(controller)
            .get("/outside") { _ -> String in
                exp4.fulfill()
                return "foo"
            }
        
        try await Test.get("/outside").assertOk()
        wait(for: [exp1, exp2, exp3, exp4], timeout: kMinTimeout)
    }
}

extension XCTestCase {
    func expectationInverted(description: String) -> XCTestExpectation {
        let exp = expectation(description: description)
        exp.isInverted = true
        return exp
    }
}

struct ExpectMiddleware: Middleware {
    let expectation: XCTestExpectation
    
    func intercept(_ request: Request, next: (Request) async throws -> Response) async throws -> Response {
        expectation.fulfill()
        return try await next(request)
    }
}

struct ActionMiddleware: Middleware {
    let action: () async -> Void
    
    func intercept(_ request: Request, next: (Request) async throws -> Response) async throws -> Response {
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
