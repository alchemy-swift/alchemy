@testable
import Alchemy
import XCTAlchemy

let kMinTimeout: TimeInterval = 0.01

final class RouterTests: TestCase<TestApp> {
    func testMatch() {
        app.get { _ in "Hello, world!" }
        app.post { _ in 1 }
        app.register(.get1)
        app.register(.post1)
        testAsync {
            let res1 = await self.app.request(TestRequest(method: .GET, path: "", response: ""))
            XCTAssertEqual(res1, "Hello, world!")
            let res2 = await self.app.request(TestRequest(method: .POST, path: "", response: ""))
            XCTAssertEqual(res2, "1")
            let res3 = await self.app.request(.get1)
            XCTAssertEqual(res3, TestRequest.get1.response)
            let res4 = await self.app.request(.post1)
            XCTAssertEqual(res4, TestRequest.post1.response)
        }
    }

    func testMissing() {
        app.register(.getEmpty)
        app.register(.get1)
        app.register(.post1)
        testAsync {
            let res1 = await self.app.request(.get2)
            XCTAssertEqual(res1, "Not Found")
            let res2 = await self.app.request(.postEmpty)
            XCTAssertEqual(res2, "Not Found")
        }
    }

    func testMiddlewareCalling() {
        let shouldFulfull = expectation(description: "The middleware should be called.")

        let mw1 = TestMiddleware(req: { request in
            shouldFulfull.fulfill()
        })

        let mw2 = TestMiddleware(req: { request in
            XCTFail("This middleware should not be called.")
        })

        self.app
            .use(mw1)
            .register(.get1)
            .use(mw2)
            .register(.post1)

        testAsync {
            _ = await self.app.request(.get1)
        }

        wait(for: [shouldFulfull], timeout: kMinTimeout)
    }

    func testMiddlewareCalledWhenError() {
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
            .register(.get1)

        testAsync {
            _ = await self.app.request(.get1)
        }

        wait(for: [globalFulfill, mw1Fulfill, mw2Fulfill], timeout: kMinTimeout)
    }

    func testGroupMiddleware() {
        let expect = expectation(description: "The middleware should be called once.")
        let mw = TestMiddleware(req: { request in
            XCTAssertEqual(request.head.uri, TestRequest.post1.path)
            XCTAssertEqual(request.head.method, TestRequest.post1.method)
            expect.fulfill()
        })

        self.app
            .group(middleware: mw) { newRouter in
                newRouter.register(.post1)
            }
            .register(.get1)

        testAsync {
            let res1 = await self.app.request(.get1)
            XCTAssertEqual(res1, TestRequest.get1.response)
            let res2 = await self.app.request(.post1)
            XCTAssertEqual(res2, TestRequest.post1.response)
        }
        
        wait(for: [expect], timeout: kMinTimeout)
    }

    func testMiddlewareOrder() {
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

        app
            .use(mw1)
            .use(mw2)
            .use(mw3)
            .register(.getEmpty)
        
        testAsync {
            _ = await self.app.request(.getEmpty)
        }

        wait(for: [mw1Req, mw1Res, mw2Req, mw2Res, mw3Req, mw3Res], timeout: kMinTimeout)
    }
    
    func testArray() {
        let array = ["Hello", "World"]
        app.get { _ in array }
        testAsync {
            let res = await self.app._request(.GET, path: "/")
            XCTAssertEqual(try res?.body?.decodeJSON(as: [String].self), array)
        }
    }

    func testQueriesIgnored() {
        app.register(.get1)
        testAsync {
            let res = await self.app.request(.get1Queries)
            XCTAssertEqual(res, TestRequest.get1.response)
        }
    }

    func testPathParametersMatch() {
        let expect = expectation(description: "The handler should be called.")

        let uuidString = UUID().uuidString
        let orderedExpectedParameters = [
            Parameter(key: "uuid", value: uuidString),
            Parameter(key: "user_id", value: "123"),
        ]

        let routeMethod = HTTPMethod.GET
        let routeToRegister = "/v1/some_path/:uuid/:user_id"
        let routeToCall = "/v1/some_path/\(uuidString)/123"
        let routeResponse = "some response"

        self.app.on(routeMethod, at: routeToRegister) { request -> ResponseConvertible in
            XCTAssertEqual(request.parameters, orderedExpectedParameters)
            expect.fulfill()

            return routeResponse
        }
        
        testAsync {
            let res = await self.app.request(TestRequest(method: routeMethod, path: routeToCall, response: ""))
            XCTAssertEqual(res, routeResponse)
        }

        wait(for: [expect], timeout: kMinTimeout)
    }

    func testMultipleRequests() {
        // What happens if a user registers the same route twice?
    }

    func testInvalidPath() {
        // What happens if a user registers an invalid path string?
    }

    func testForwardSlashIssues() {
        // Could update the router to automatically add "/" if URI strings are missing them,
        // automatically add/remove trailing "/", etc.
    }

    func testGroupedPathPrefix() {
        app
            .grouped("group") { app in
                app
                    .register(.get1)
                    .register(.get2)
                    .grouped("/nested") { app in
                        app.register(.post1)
                    }
                    .register(.post2)
            }
            .register(.get3)

        testAsync {
            let res = await self.app.request(TestRequest(
                method: .GET,
                path: "/group\(TestRequest.get1.path)",
                response: TestRequest.get1.path
            ))
            XCTAssertEqual(res, TestRequest.get1.response)

            let res2 = await self.app.request(TestRequest(
                method: .GET,
                path: "/group\(TestRequest.get2.path)",
                response: TestRequest.get2.path
            ))
            XCTAssertEqual(res2, TestRequest.get2.response)

            let res3 = await self.app.request(TestRequest(
                method: .POST,
                path: "/group/nested\(TestRequest.post1.path)",
                response: TestRequest.post1.path
            ))
            XCTAssertEqual(res3, TestRequest.post1.response)

            let res4 = await self.app.request(TestRequest(
                method: .POST,
                path: "/group\(TestRequest.post2.path)",
                response: TestRequest.post2.path
            ))
            XCTAssertEqual(res4, TestRequest.post2.response)

            // only available under group prefix
            let res5 = await self.app.request(TestRequest.get1)
            XCTAssertEqual(res5, "Not Found")
            let res6 = await self.app.request(TestRequest.get2)
            XCTAssertEqual(res6, "Not Found")
            let res7 = await self.app.request(TestRequest.post1)
            XCTAssertEqual(res7, "Not Found")
            let res8 = await self.app.request(TestRequest.post2)
            XCTAssertEqual(res8, "Not Found")

            // defined outside group --> still available without group prefix
            let res9 = await self.app.request(TestRequest.get3)
            XCTAssertEqual(res9, TestRequest.get3.response)
        }
    }
    
    func testErrorHandling() {
        app.put { _ -> String in
            throw NonConvertibleError()
        }
        
        app.get { _ -> String in
            throw ConvertibleError(shouldThrowWhenConverting: false)
        }
        
        app.post { _ -> String in
            throw ConvertibleError(shouldThrowWhenConverting: true)
        }
        
        testAsync {
            let res1 = await self.app._request(.GET, path: "/")
            XCTAssertEqual(res1?.status, .badGateway)
            XCTAssert(res1?.body == nil)
            let res2 = await self.app._request(.POST, path: "/")
            XCTAssertEqual(res2?.status, .internalServerError)
            XCTAssert(res2?.body?.decodeString() == "Internal Server Error")
            let res3 = await self.app._request(.PUT, path: "/")
            XCTAssertEqual(res3?.status, .internalServerError)
            XCTAssert(res3?.body?.decodeString() == "Internal Server Error")
        }
    }
}

struct ConvertibleError: Error, ResponseConvertible {
    let shouldThrowWhenConverting: Bool
    
    func convert() async throws -> Response {
        if shouldThrowWhenConverting {
            throw NonConvertibleError()
        }
        
        return Response(status: .badGateway, body: nil)
    }
}

struct NonConvertibleError: Error {}

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

extension Application {
    @discardableResult
    func register(_ test: TestRequest) -> Self {
        self.on(test.method, at: test.path, use: { _ in test.response })
    }
    
    func request(_ test: TestRequest) async -> String? {
        return await _request(test.method, path: test.path)?.body?.decodeString()
    }
    
    func _request(_ method: HTTPMethod, path: String) async -> Response? {
        return await Router.default.handle(
            request: Request(
                head: .init(
                    version: .init(
                        major: 1,
                        minor: 1
                    ),
                    method: method,
                    uri: path,
                    headers: .init()),
                bodyBuffer: nil
            )
        )
    }
}

struct TestApp: Application {
    func boot() {}
}

struct TestRequest {
    let method: HTTPMethod
    let path: String
    let response: String

    static let postEmpty = TestRequest(method: .POST, path: "", response: "post empty")
    static let post1 = TestRequest(method: .POST, path: "/something", response: "post 1")
    static let post2 = TestRequest(method: .POST, path: "/something/else", response: "post 2")
    static let post3 = TestRequest(method: .POST, path: "/something_else", response: "post 3")

    static let getEmpty = TestRequest(method: .GET, path: "", response: "get empty")
    static let get1 = TestRequest(method: .GET, path: "/something", response: "get 1")
    static let get1Queries = TestRequest(method: .GET, path: "/something?some=value&other=2", response: "get 1")
    static let get2 = TestRequest(method: .GET, path: "/something/else", response: "get 2")
    static let get3 = TestRequest(method: .GET, path: "/something_else", response: "get 3")
}
