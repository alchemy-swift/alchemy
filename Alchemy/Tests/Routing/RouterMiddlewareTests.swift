import AlchemyTesting

@Suite(.mockTestApp)
struct RouterMiddlewareTests {
    @Test func testMiddlewareCalling() async throws {
        var (one, two) = (false, false)
        let mw1 = TestMiddleware(req: { _ in one = true })
        let mw2 = TestMiddleware(req: { _ in two = true })

        Main.use(mw1)
            .get("/foo") { _ in }
            .use(mw2)
            .post("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        #expect(one)
        #expect(!two)
    }

    @Test func testMiddlewareNotCalledWhenError() async throws {
        var (one, two, three) = (false, false, false)
        let global = TestMiddleware(res: { _ in one = true })
        let mw1 = TestMiddleware(res: { _ in two = true })
        let mw2 = TestMiddleware(req: { _ in
            struct SomeError: Error {}
            three = true
            throw SomeError()
        })

        Main.useAll(global)
            .use(mw1)
            .use(mw2)
            .get("/foo") { _ in }

        _ = try await Test.get("/foo")
        
        #expect(!one)
        #expect(!two)
        #expect(three)
    }

    @Test func testGroupMiddleware() async throws {
        var one = false
        let mw = TestMiddleware(req: { request in
            #expect(request.path == "/foo")
            #expect(request.method == .post)
            one = true
        })

        Main.grouping(middlewares: [mw]) {
            $0.post("/foo") { _ in 1 }
        }
        .get("/foo") { _ in 2 }

        let res1 = try await Test.get("/foo").expectOk().expectBody("2")
        #expect(res1.status == .ok)
        #expect(res1.body?.string == "2")
        let res2 = try await Test.post("/foo").expectOk().expectBody("1")
        #expect(res2.status == .ok)
        #expect(res2.body?.string == "1")
        #expect(one)
    }
    
    @Test func testGroupMiddlewareRemoved() async throws {
        var (one, two) = (false, false)
        let mw = ActionMiddleware { one = true }

        Main.grouping(middlewares: [mw]) {
            $0.get("/foo") { _ in 1 }
        }
        .get("/bar") { _ async -> Int in
            two = true
            return 2
        }

        let res = try await Test.get("/bar")
        #expect(res.status == .ok)
        #expect(!one)
        #expect(two)
    }

    @Test func testMiddlewareOrder() async throws {
        var (one, two, three, four, five, six) = (false, false, false, false, false, false)
        var stack = [Int]()
        let mw1 = TestMiddleware { _ in
            #expect(stack == [])
            one = true
            stack.append(0)
        } res: { _ in
            #expect(stack == [0,1,2,3,4])
            two = true
        }

        let mw2 = TestMiddleware { _ in
            #expect(stack == [0])
            three = true
            stack.append(1)
        } res: { _ in
            #expect(stack == [0,1,2,3])
            four = true
            stack.append(4)
        }

        let mw3 = TestMiddleware { _ in
            #expect(stack == [0,1])
            five = true
            stack.append(2)
        } res: { _ in
            #expect(stack == [0,1,2])
            six = true
            stack.append(3)
        }

        Main.use(mw1, mw2, mw3).get("/foo") { _ in }
        _ = try await Test.get("/foo")
        #expect(one)
        #expect(two)
        #expect(three)
        #expect(four)
        #expect(five)
        #expect(six)
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
