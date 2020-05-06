import NIO
import NIOHTTP1
import XCTest
@testable import Alchemy

let kMinTimeout: TimeInterval = 0.01

final class RouterTests: XCTestCase {
    typealias TestRouter = Router<HTTPRequest, String>
    
    private var router = TestRouter { $0 }
    private var loop = EmbeddedEventLoop()
    
    override func setUp() {
        super.setUp()
        self.router = TestRouter { $0 }
        self.loop = EmbeddedEventLoop()
    }
    
    func testMatch() throws {
        self.router.register(.getEmpty)
        self.router.register(.get1)
        self.router.register(.post1)
        XCTAssertEqual(try self.router.request(.getEmpty), Request.getEmpty.response)
        XCTAssertEqual(try self.router.request(.get1), Request.get1.response)
        XCTAssertEqual(try self.router.request(.post1), Request.post1.response)
    }
    
    func testMissing() throws {
        self.router.register(.getEmpty)
        self.router.register(.get1)
        self.router.register(.post1)
        XCTAssertEqual(try self.router.request(.get2), nil)
        XCTAssertEqual(try self.router.request(.postEmpty), nil)
    }
    
    func testMiddlewareCalling() throws {
        let shouldFulfull = expectation(description: "The middleware should be called.")
        
        let mw1 = VoidMiddleware(callback: { request in
            shouldFulfull.fulfill()
        })
        
        let mw2 = VoidMiddleware(callback: { request in
            XCTFail("This middleware should not be called.")
        })
        
        self.router.middleware(mw1)
            .register(.get1)
            .middleware(mw2)
            .register(.post1)

        _ = try self.router.request(.get1)
        
        wait(for: [shouldFulfull], timeout: kMinTimeout)
    }
    
    func testMiddlewareMapping() throws {
        let shouldFulfull = expectation(description: "The middleware should be called.")
        let expectedResult = Int.random(in: Int.min...Int.max)
        let req = Request.post1
        let mw = MappingMiddleware { _ in expectedResult }
        self.router.middleware(mw)
            .add(
                handler: { req, result in
                    XCTAssertEqual(result, expectedResult)
                    shouldFulfull.fulfill()
                    return "\(result)"
                },
                for: req.method,
                path: req.path
            )
        _ = try self.router.request(req)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testPath() throws {
        let thePath = "/the_path"
        self.router.path(thePath)
            .register(.post1)
        
        XCTAssertEqual(try self.router.request(Request.post1.prefixingPath(with: thePath)),
                       Request.post1.response)
        XCTAssertNil(try self.router.request(.post1))
        XCTAssertNil(try self.router.request(.get1))
    }
    
    func testGroupPath() throws {
        let thePath = "/group_path"
        self.router
            .group(path: thePath) { newRouter in
                newRouter.register(.post1)
            }
            .register(.get1)
        
        XCTAssertNil(try self.router.request(.post1))
        XCTAssertNil(try self.router.request(Request.get1.prefixingPath(with: thePath)))
        XCTAssertEqual(try self.router.request(.get1), Request.get1.response)
        XCTAssertEqual(try self.router.request(Request.post1.prefixingPath(with: thePath)),
                       Request.post1.response)
    }
    
    func testGroupMiddleware() {
        let expect = expectation(description: "The middleware should be called once.")
        let mw = VoidMiddleware { request in
            XCTAssertEqual(request.head.uri, Request.post1.path)
            XCTAssertEqual(request.head.method, Request.post1.method)
            expect.fulfill()
        }
        
        self.router
            .group(middleware: mw) { newRouter in
                newRouter.register(.post1)
            }
            .register(.get1)
        
        XCTAssertEqual(try self.router.request(.get1), Request.get1.response)
        XCTAssertEqual(try self.router.request(.post1), Request.post1.response)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testQueriesIgnored() {
        self.router.register(.get1)
        XCTAssertEqual(try self.router.request(.get1Queries), Request.get1.response)
    }
    
    func testPathParametersMatch() {
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
        
        self.router.on(routeMethod, at: routeToRegister) { request -> String in
            XCTAssertEqual(request.pathParameters, orderedExpectedParameters)
            expect.fulfill()
            return routeResponse
        }
        
        XCTAssertEqual(try self.router.request(Request(method: routeMethod, path: routeToCall, response: "")),
                       routeResponse)
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
}

extension RouterTests.TestRouter {
    @discardableResult
    fileprivate func register(_ request: Request) -> Self {
        self.on(request.method, at: request.path, do: { _ in request.response })
    }
    
    fileprivate func request(_ request: Request) throws -> String? {
        try self.handle(
            request: HTTPRequest(
                eventLoop: EmbeddedEventLoop(),
                head: HTTPRequestHead(
                    version: .init(major: 1, minor: 1),
                    method: request.method,
                    uri: request.path),
                bodyBuffer: nil))
    }
}

/// Runs the specified callback on a request.
struct VoidMiddleware: Middleware {
    let callback: (HTTPRequest) -> Void
    
    func intercept(_ request: HTTPRequest) throws -> Void {
        self.callback(request)
    }
}

/// Maps the request into the given `Int`.
struct MappingMiddleware: Middleware {
    let callback: (HTTPRequest) -> Int
    
    func intercept(_ request: HTTPRequest) throws -> Int {
        self.callback(request)
    }
}

struct Request {
    let method: HTTPMethod
    let path: String
    let response: String
    
    func prefixingPath(with prefix: String) -> Request {
        Request(method: self.method, path: prefix + self.path, response: self.response)
    }
    
    static let postEmpty = Request(method: .POST, path: "", response: "post empty")
    static let post1 = Request(method: .POST, path: "/something", response: "post 1")
    static let post2 = Request(method: .POST, path: "/something/else", response: "post 2")
    static let post3 = Request(method: .POST, path: "/something_else", response: "post 3")
    
    static let getEmpty = Request(method: .GET, path: "", response: "get empty")
    static let get1 = Request(method: .GET, path: "/something", response: "get 1")
    static let get1Queries = Request(method: .GET, path: "/something?some=value&other=2", response: "get 1")
    static let get2 = Request(method: .GET, path: "/something/else", response: "get 2")
    static let get3 = Request(method: .GET, path: "/something_else", response: "get 3")
    
    static let pathParameterEscaped = Request(method: .GET, path: "/parameter/:id", response: "path param")
    static let pathParameterValue = Request(method: .GET, path: "/parameter/123", response: "path param")
}
