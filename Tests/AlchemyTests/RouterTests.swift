import NIO
import NIOHTTP1
import XCTest
@testable import Alchemy

final class RouterTests: XCTestCase {
    typealias TestRouter = Router<HTTPRequest, String>
    
    var router = TestRouter(mapper: { $0 })
    var loop = EmbeddedEventLoop()
    
    override func setUp() {
        super.setUp()
        self.router = TestRouter(mapper: { $0 })
        self.loop = EmbeddedEventLoop()
    }
    
    func testMethodMatch() throws {
        let request = self.createRequest(method: .POST, uri: "")
        self.router.on(.POST, do: { _ in "hello test" })
        let result = try self.router.handle(request: request)
        XCTAssertEqual(result, "hello test")
    }
    
    func testExample() {
        
    }
    
    private func createRequest(method: HTTPMethod, uri: String) -> HTTPRequest {
        HTTPRequest(
            eventLoop: self.loop,
            head: HTTPRequestHead(
                version: .init(major: 1, minor: 1),
                method: method,
                uri: uri),
            bodyBuffer: nil)
    }
}

private extension ByteBuffer {
    func entireAsString() -> String? {
        return self.getString(at: 0, length: self.readableBytes)
    }
}

private struct SomeMiddleware: Middleware {
    let action: (HTTPRequest) -> Void
    
    func intercept(_ input: HTTPRequest) -> Void {
        action(input)
    }
}


/**
 self.router
     // Applied to all subsequent routes
     .middleware(LoggingMiddleware())
     // Group all requests to /users
     .group(path: "/users") {
         // `POST /users`
         $0.on(.POST, do: { req in "hi from create user" })
             // `POST /users/reset`
             .on(.POST, at: "/reset", do: { req in "hi from user reset" })
             // Applies to the rest of the requests in this chain, giving them a `User` parameter.
             .middleware(BasicAuthMiddleware<User>())
             // `POST /users/login`
             .on(.POST, at: "/login") { req, authedUser in "hi from user login" }
     }
     // Applies to requests in this group, validating a token auth and giving them a `User` parameter.
     .group(with: TokenAuthMiddleware<User>()) {
         // Applies to the rest of the requests in this chain.
         $0.path("/todo")
             // `POST /todo`
             .on(.POST) { req, user in "hi from todo create" }
             // `PUT /todo`
             .on(.POST) { req, user in "hi from todo update" }
             // `DELETE /todo`
             .on(.DELETE) { req, user in "hi from todo delete" }

         // Abstraction for handling requests related to friends.
         let friends = FriendsController()

         // Applies to the rest of the requests in this chain.
         $0.path("/friends")
             // `POST /friends`
             .on(.POST, do: friends.message)
             // `DELETE /friends`
             .on(.DELETE, do: friends.remove)
             // `POST /friends/message`
             .on(.POST, at: "/message", do: friends.message)
 */
