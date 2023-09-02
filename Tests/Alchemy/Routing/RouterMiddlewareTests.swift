import AlchemyTest

final class RouterMiddlewareTests: TestCase<TestApp> {
    func testMiddlewareCalling() async throws {
        var expect = Expect()
        let mw1 = TestMiddleware(req: { _ in expect.signalOne() })
        let mw2 = TestMiddleware(req: { _ in expect.signalTwo() })

        app.use(mw1)
            .get("/foo") { _ in }
            .use(mw2)
            .post("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        AssertTrue(expect.one)
        AssertFalse(expect.two)
    }

    func testMiddlewareNotCalledWhenError() async throws {
        var expect = Expect()
        let global = TestMiddleware(res: { _ in expect.signalOne() })
        let mw1 = TestMiddleware(res: { _ in expect.signalTwo() })
        let mw2 = TestMiddleware(req: { _ in
            struct SomeError: Error {}
            expect.signalThree()
            throw SomeError()
        })

        app.useAll(global)
            .use(mw1)
            .use(mw2)
            .get("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        AssertFalse(expect.one)
        AssertFalse(expect.two)
        AssertTrue(expect.three)
    }

    func testGroupMiddleware() async throws {
        var expect = Expect()
        let mw = TestMiddleware(req: { request in
            XCTAssertEqual(request.path, "/foo")
            XCTAssertEqual(request.method, .POST)
            expect.signalOne()
        })

        app.grouping(middlewares: [mw]) {
            $0.post("/foo") { _ in 1 }
        }
        .get("/foo") { _ in 2 }

        try await Test.get("/foo").assertOk().assertBody("2")
        try await Test.post("/foo").assertOk().assertBody("1")
        AssertTrue(expect.one)
    }
    
    func testGroupMiddlewareRemoved() async throws {
        var exp = Expect()
        let mw = ActionMiddleware { exp.signalOne() }

        app.grouping(middlewares: [mw]) {
            $0.get("/foo") { _ in 1 }
        }
        .get("/bar") { _ async -> Int in
            exp.signalTwo()
            return 2
        }

        try await Test.get("/bar").assertOk()
        AssertFalse(exp.one)
        AssertTrue(exp.two)
    }

    func testMiddlewareOrder() async throws {
        var stack = [Int]()
        var expect = Expect()
        let mw1 = TestMiddleware { _ in
            XCTAssertEqual(stack, [])
            expect.signalOne()
            stack.append(0)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3,4])
            expect.signalTwo()
        }

        let mw2 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0])
            expect.signalThree()
            stack.append(1)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3])
            expect.signalFour()
            stack.append(4)
        }

        let mw3 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0,1])
            expect.signalFive()
            stack.append(2)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2])
            expect.signalSix()
            stack.append(3)
        }

        app.use(mw1, mw2, mw3).get("/foo") { _ in }
        _ = try await Test.get("/foo")
        AssertTrue(expect.one)
        AssertTrue(expect.two)
        AssertTrue(expect.three)
        AssertTrue(expect.four)
        AssertTrue(expect.five)
        AssertTrue(expect.six)
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
