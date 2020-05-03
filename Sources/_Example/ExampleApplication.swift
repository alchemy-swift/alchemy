import Alchemy
import NIO

struct MultipleDatabases {
    // Singleton
    @Inject
    var mySQL: MySQLDatabase
    
    // Multiple singletons of same type
    @Inject("postgres1")
    var postgres1: PostgresDatabase
    
    @Inject("postgres2")
    var postgres2: PostgresDatabase
}

struct APIServer: Application {
    let eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    @Inject var db: PostgresDatabase
    @Inject var router: HTTPRouter
    @Inject var globalMiddlewares: GlobalMiddlewares
    
    func setup() {
        self.db.configure(with: .main, eventLoopGroup: self.eventLoopGroup)
        
        self.globalMiddlewares
            // Applied to all incoming requests.
            .add(LoggingMiddleware(text: "Received request:"))
        
        self.router
            // Applied to all subsequent routes
            .middleware(LoggingMiddleware(text: "Handling request:"))
            // `GET /json`
            .on(.GET, at: "/json", do: { _ in SampleJSON() })
            // Group all requests to /users
            .group(path: "/users") {
                $0.on(.POST, do: { req in "hi from create user" })
                    // `POST /users/reset`
                    .on(.POST, at: "/reset", do: { req in "hi from user reset" })
                    // Applies to the rest of the requests in this chain, giving them a `User` parameter.
                    .middleware(BasicAuthMiddleware<User>())
                    // `POST /users/login`
                    .on(.POST, at: "/login") { req, authedUser in "hi from user login" }
            }
            // Applies to requests in this group, validating a token auth and giving them a `User` parameter.
            .group(middleware: TokenAuthMiddleware<User>()) {
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
            }
            .on(.GET, at: "/db", do: DatabaseTestController().test)
    }
}

struct DatabaseTestController {
    @Inject var db: PostgresDatabase
    
    func test(req: HTTPRequest) -> EventLoopFuture<String> {
        db.test(on: req.eventLoop)
    }
}

struct SampleJSON: Encodable {
    let one = "value1"
    let two = "value2"
    let three = "value3"
    let four = 4
}

struct LoggingMiddleware: Middleware {
    let text: String
    
    func intercept(_ request: HTTPRequest) throws -> Void {
        print("\(self.text) '\(request.head.method.rawValue) \(request.head.uri)'")
    }
}
