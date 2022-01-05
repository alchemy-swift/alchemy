import AlchemyTest

final class ApplicationControllerTests: TestCase<TestApp> {
    func testController() async throws {
        try await Test.get("/test").assertNotFound()
        app.controller(TestController())
        try await Test.get("/test").assertOk()
    }
    
    func testControllerMiddleware() async throws {
        let exp1 = expectation(description: "")
        let exp2 = expectation(description: "")
        let exp3 = expectation(description: "")
        let controller = MiddlewareController(middlewares: [
            ExpectMiddleware(expectation: exp1),
            ExpectMiddleware(expectation: exp2),
            ExpectMiddleware(expectation: exp3)
        ])
        app.controller(controller)
        try await Test.get("/middleware").assertOk()
        await waitForExpectations(timeout: kMinTimeout)
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
        await waitForExpectations(timeout: kMinTimeout)
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
