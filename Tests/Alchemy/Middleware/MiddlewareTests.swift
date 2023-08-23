import AlchemyTest

final class MiddlewareTests: TestCase<TestApp> {
    func testMiddlewareCalling() async throws {
        let expect = Expect()
        let mw1 = TestMiddleware(req: { _ in await expect.signalOne() })
        let mw2 = TestMiddleware(req: { _ in await expect.signalTwo() })

        app.use(mw1)
            .get("/foo") { _ in }
            .use(mw2)
            .post("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        AssertTrue(await expect.one)
        AssertFalse(await expect.two)
    }

    func testMiddlewareCalledWhenError() async throws {
        let expect = Expect()
        let global = TestMiddleware(res: { _ in await expect.signalOne() })
        let mw1 = TestMiddleware(res: { _ in await expect.signalTwo() })
        let mw2 = TestMiddleware(req: { _ in
            struct SomeError: Error {}
            await expect.signalThree()
            throw SomeError()
        })

        app.useAll(global)
            .use(mw1)
            .use(mw2)
            .get("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        AssertTrue(await expect.one)
        AssertTrue(await expect.two)
        AssertTrue(await expect.three)
    }

    func testGroupMiddleware() async throws {
        let expect = Expect()
        let mw = TestMiddleware(req: { request in
            XCTAssertEqual(request.path, "/foo")
            XCTAssertEqual(request.method, .POST)
            await expect.signalOne()
        })

        app.group(mw) {
            $0.post("/foo") { _ in 1 }
        }
        .get("/foo") { _ in 2 }

        try await Test.get("/foo").assertOk().assertBody("2")
        try await Test.post("/foo").assertOk().assertBody("1")
        AssertTrue(await expect.one)
    }
    
    func testGroupMiddlewareRemoved() async throws {
        let exp = Expect()
        let mw = ActionMiddleware { await exp.signalOne() }

        app.group(mw) {
            $0.get("/foo") { _ in 1 }
        }
        .get("/bar") { _ async -> Int in
            await exp.signalTwo()
            return 2
        }

        try await Test.get("/bar").assertOk()
        AssertFalse(await exp.one)
        AssertTrue(await exp.two)
    }

    func testMiddlewareOrder() async throws {
        var stack = [Int]()
        let expect = Expect()
        let mw1 = TestMiddleware { _ in
            XCTAssertEqual(stack, [])
            await expect.signalOne()
            stack.append(0)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3,4])
            await expect.signalTwo()
        }

        let mw2 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0])
            await expect.signalThree()
            stack.append(1)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3])
            await expect.signalFour()
            stack.append(4)
        }

        let mw3 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0,1])
            await expect.signalFive()
            stack.append(2)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2])
            await expect.signalSix()
            stack.append(3)
        }

        app.use(mw1, mw2, mw3).get("/foo") { _ in }
        _ = try await Test.get("/foo")
        AssertTrue(await expect.one)
        AssertTrue(await expect.two)
        AssertTrue(await expect.three)
        AssertTrue(await expect.four)
        AssertTrue(await expect.five)
        AssertTrue(await expect.six)
    }
}

/// Runs the specified callback on a request / response.
struct TestMiddleware: Middleware {
    var req: ((Request) async throws -> Void)?
    var res: ((Response) async throws -> Void)?

    func handle(_ request: Request, next: Next) async throws -> Response {
        try await req?(request)
        let response = try await next(request)
        try await res?(response)
        return response
    }
}

