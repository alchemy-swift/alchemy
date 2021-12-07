import AlchemyTest

final class MiddlewareTests: TestCase<TestApp> {
    func testMiddlewareCalling() async throws {
        let expect = expectation(description: "The middleware should be called.")
        let mw1 = TestMiddleware(req: { _ in expect.fulfill() })
        let mw2 = TestMiddleware(req: { _ in XCTFail("This middleware should not be called.") })

        app.use(mw1)
            .get("/foo") { _ in }
            .use(mw2)
            .post("/foo") { _ in }

        _ = try await get("/foo")

        wait(for: [expect], timeout: kMinTimeout)
    }

    func testMiddlewareCalledWhenError() async throws {
        let globalFulfill = expectation(description: "")
        let global = TestMiddleware(res: { _ in globalFulfill.fulfill() })

        let mw1Fulfill = expectation(description: "")
        let mw1 = TestMiddleware(res: { _ in mw1Fulfill.fulfill() })

        let mw2Fulfill = expectation(description: "")
        let mw2 = TestMiddleware(req: { _ in
            struct SomeError: Error {}
            mw2Fulfill.fulfill()
            throw SomeError()
        })

        app.useAll(global)
            .use(mw1)
            .use(mw2)
            .get("/foo") { _ in }

        _ = try await get("/foo")

        wait(for: [globalFulfill, mw1Fulfill, mw2Fulfill], timeout: kMinTimeout)
    }

    func testGroupMiddleware() async throws {
        let expect = expectation(description: "The middleware should be called once.")
        let mw = TestMiddleware(req: { request in
            XCTAssertEqual(request.path, "/foo")
            XCTAssertEqual(request.method, .POST)
            expect.fulfill()
        })

        app.group(mw) {
            $0.post("/foo") { _ in 1 }
        }
        .get("/foo") { _ in 2 }

        try await get("/foo").assertOk().assertBody("2")
        try await post("/foo").assertOk().assertBody("1")
        wait(for: [expect], timeout: kMinTimeout)
    }

    func testMiddlewareOrder() async throws {
        var stack = [Int]()
        let mw1Req = expectation(description: "")
        let mw1Res = expectation(description: "")
        let mw1 = TestMiddleware { _ in
            XCTAssertEqual(stack, [])
            mw1Req.fulfill()
            stack.append(0)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3,4])
            mw1Res.fulfill()
        }

        let mw2Req = expectation(description: "")
        let mw2Res = expectation(description: "")
        let mw2 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0])
            mw2Req.fulfill()
            stack.append(1)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2,3])
            mw2Res.fulfill()
            stack.append(4)
        }

        let mw3Req = expectation(description: "")
        let mw3Res = expectation(description: "")
        let mw3 = TestMiddleware { _ in
            XCTAssertEqual(stack, [0,1])
            mw3Req.fulfill()
            stack.append(2)
        } res: { _ in
            XCTAssertEqual(stack, [0,1,2])
            mw3Res.fulfill()
            stack.append(3)
        }

        app.use(mw1, mw2, mw3).get("/foo") { _ in }
        _ = try await get("/foo")

        wait(for: [mw1Req, mw1Res, mw2Req, mw2Res, mw3Req, mw3Res], timeout: kMinTimeout)
    }
}

/// Runs the specified callback on a request / response.
struct TestMiddleware: Middleware {
    var req: ((Request) throws -> Void)?
    var res: ((Response) throws -> Void)?

    func intercept(_ request: Request, next: Next) async throws -> Response {
        try req?(request)
        let response = try await next(request)
        try res?(response)
        return response
    }
}
