import AlchemyTesting

final class RouterMiddlewareTests: TestCase<TestApp> {
    func testMiddlewareCalling() async throws {
        var (one, two) = (false, false)
        let mw1 = TestMiddleware(req: { _ in one = true })
        let mw2 = TestMiddleware(req: { _ in two = true })

        app.use(mw1)
            .get("/foo") { _ in }
            .use(mw2)
            .post("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        AssertTrue(one)
        AssertFalse(two)
    }

    func testMiddlewareNotCalledWhenError() async throws {
        var (one, two, three) = (false, false, false)
        let global = TestMiddleware(res: { _ in one = true })
        let mw1 = TestMiddleware(res: { _ in two = true })
        let mw2 = TestMiddleware(req: { _ in
            struct SomeError: Error {}
            three = true
            throw SomeError()
        })

        app.useAll(global)
            .use(mw1)
            .use(mw2)
            .get("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        AssertFalse(one)
        AssertFalse(two)
        AssertTrue(three)
    }

    func testGroupMiddleware() async throws {
        var one = false
        let mw = TestMiddleware(req: { request in
            XCTAssertEqual(request.path, "/foo")
            XCTAssertEqual(request.method, .post)
            one = true
        })

        app.grouping(middlewares: [mw]) {
            $0.post("/foo") { _ in 1 }
        }
        .get("/foo") { _ in 2 }

        try await Test.get("/foo").assertOk().assertBody("2")
        try await Test.post("/foo").assertOk().assertBody("1")
        AssertTrue(one)
    }
    
    func testGroupMiddlewareRemoved() async throws {
        var (one, two) = (false, false)
        let mw = ActionMiddleware { one = true }

        app.grouping(middlewares: [mw]) {
            $0.get("/foo") { _ in 1 }
        }
        .get("/bar") { _ async -> Int in
            two = true
            return 2
        }

        try await Test.get("/bar").assertOk()
        AssertFalse(one)
        AssertTrue(two)
    }

    func testMiddlewareOrder() async throws {
        var (one, two, three, four, five, six) = (false, false, false, false, false, false)
        var stack = [Int]()
        let mw1 = TestMiddleware { _ in
            XCTAssertEqual(stack, [])
            one = true
            stack.append(0)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3,4])
            two = true
        }

        let mw2 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0])
            three = true
            stack.append(1)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3])
            four = true
            stack.append(4)
        }

        let mw3 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0,1])
            five = true
            stack.append(2)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2])
            six = true
            stack.append(3)
        }

        app.use(mw1, mw2, mw3).get("/foo") { _ in }
        _ = try await Test.get("/foo")
        AssertTrue(one)
        AssertTrue(two)
        AssertTrue(three)
        AssertTrue(four)
        AssertTrue(five)
        AssertTrue(six)
    }
}

/// Runs the specified callback on a request / response.
private struct TestMiddleware: Middleware {
    var req: ((Request) async throws -> Void)?
    var res: ((Response) async throws -> Void)?

    func handle(_ request: Request, next: Next) async throws -> Response {
        try await req?(request)
        let response = try await next(request)
        try await res?(response)
        return response
    }
}
