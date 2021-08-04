import NIO
import NIOHTTP1
import XCTest
@testable import Alchemy

let kMinTimeout: TimeInterval = 0.01

final class RouterTests: XCTestCase {
    private var app = TestApp()

    override func setUp() {
        super.setUp()
        Services.mock()
        self.app = TestApp()
    }
    
    func testMatch() throws {
        self.app.get { _ in "Hello, world!" }
        self.app.post { _ in 1 }
        self.app.register(.get1)
        self.app.register(.post1)
        XCTAssertEqual(try self.app.request(TestRequest(method: .GET, path: "", response: "")), "Hello, world!")
        XCTAssertEqual(try self.app.request(TestRequest(method: .POST, path: "", response: "")), "1")
        XCTAssertEqual(try self.app.request(.get1), TestRequest.get1.response)
        XCTAssertEqual(try self.app.request(.post1), TestRequest.post1.response)
    }

    func testMissing() throws {
        self.app.register(.getEmpty)
        self.app.register(.get1)
        self.app.register(.post1)
        XCTAssertEqual(try self.app.request(.get2), nil)
        XCTAssertEqual(try self.app.request(.postEmpty), nil)
    }

    func testMiddlewareCalling() throws {
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

        _ = try self.app.request(.get1)

        wait(for: [shouldFulfull], timeout: kMinTimeout)
    }
    
    func testMiddlewareCalledWhenError() throws {
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
        
        _ = try app.request(.get1)
        
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

        XCTAssertEqual(try self.app.request(.get1), TestRequest.get1.response)
        XCTAssertEqual(try self.app.request(.post1), TestRequest.post1.response)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testMiddlewareOrder() throws {
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
        
        self.app
            .use(mw1)
            .use(mw2)
            .use(mw3)
            .register(.getEmpty)
        
        _ = try self.app.request(.getEmpty)
        
        waitForExpectations(timeout: kMinTimeout)
    }

    func testQueriesIgnored() {
        self.app.register(.get1)
        XCTAssertEqual(try self.app.request(.get1Queries), TestRequest.get1.response)
    }

    func testPathParametersMatch() throws {
        let expect = expectation(description: "The handler should be called.")

        let uuidString = UUID().uuidString
        let orderedExpectedParameters = [
            PathParameter(parameter: "uuid", stringValue: uuidString),
            PathParameter(parameter: "user_id", stringValue: "123"),
        ]

        let routeMethod = HTTPMethod.GET
        let routeToRegister = "/v1/some_path/:uuid/:user_id"
        let routeToCall = "/v1/some_path/\(uuidString)/123"
        let routeResponse = "some response"

        self.app.on(routeMethod, at: routeToRegister) { request -> ResponseConvertible in
            XCTAssertEqual(request.pathParameters, orderedExpectedParameters)
            expect.fulfill()
            
            return routeResponse
        }
        
        let res = try self.app.request(TestRequest(method: routeMethod, path: routeToCall, response: ""))
        print(res ?? "N/A")

        XCTAssertEqual(res, routeResponse)
        waitForExpectations(timeout: kMinTimeout)
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

    func testGroupedPathPrefix() throws {
        self.app
            .grouped("group") { app in
                app
                    .register(.get1)
                    .register(.get2)
                    .grouped("nested") { app in
                        app.register(.post1)
                    }
                    .register(.post2)
            }
            .register(.get3)

        XCTAssertEqual(try self.app.request(TestRequest(
            method: .GET,
            path: "/group\(TestRequest.get1.path)",
            response: TestRequest.get1.path
        )), TestRequest.get1.response)

        XCTAssertEqual(try self.app.request(TestRequest(
            method: .GET,
            path: "/group\(TestRequest.get2.path)",
            response: TestRequest.get2.path
        )), TestRequest.get2.response)

        XCTAssertEqual(try self.app.request(TestRequest(
            method: .POST,
            path: "/group/nested\(TestRequest.post1.path)",
            response: TestRequest.post1.path
        )), TestRequest.post1.response)

        XCTAssertEqual(try self.app.request(TestRequest(
            method: .POST,
            path: "/group\(TestRequest.post2.path)",
            response: TestRequest.post2.path
        )), TestRequest.post2.response)

        // only available under group prefix
        XCTAssertNil(try self.app.request(TestRequest.get1))
        XCTAssertNil(try self.app.request(TestRequest.get2))
        XCTAssertNil(try self.app.request(TestRequest.post1))
        XCTAssertNil(try self.app.request(TestRequest.post2))

        // defined outside group --> still available without group prefix
        XCTAssertEqual(try self.app.request(TestRequest.get3), TestRequest.get3.response)
    }
}

/// Runs the specified callback on a request / response.
struct TestMiddleware: Middleware {
    var req: ((Request) throws -> Void)?
    var res: ((Response) throws -> Void)?

    func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response> {
        try req?(request)
        return next(request)
            .flatMapThrowing { response in
                try res?(response)
                return response
            }
    }
}

extension Application {
    @discardableResult
    func register(_ test: TestRequest) -> Self {
        self.on(test.method, at: test.path, handler: { _ in test.response })
    }
    
    func request(_ test: TestRequest) throws -> String? {
        return try Services.router.handle(
            request: Request(
                head: .init(
                    version: .init(
                        major: 1,
                        minor: 1
                    ),
                    method: test.method,
                    uri: test.path,
                    headers: .init()),
                bodyBuffer: nil
            )
        ).wait().body?.decodeString()
    }
}

struct TestApp: Application {
    func setup() {}
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
