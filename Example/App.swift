import Alchemy

struct Route {
    let method: HTTPMethod
    let path: String
    var options: RouteOptions
    let handler: (Request) async throws -> ResponseConvertible

    init(method: HTTPMethod, path: String, options: RouteOptions = [], handler: @escaping (Request) async throws -> ResponseConvertible) {
        self.method = method
        self.path = path
        self.options = options
        self.handler = handler
    }

    init(method: HTTPMethod, path: String, options: RouteOptions = [], handler: @escaping (Request) async throws -> Void) {
        self.method = method
        self.path = path
        self.options = options
        self.handler = {
            try await handler($0)
            return Response(status: .ok)
        }
    }
}

@Application
struct App {
    func boot() throws {
        use(SomeController())
    }

    @GET("/query")
    func query(name: String) -> String {
        "Hi, \(name)!"
    }

    @POST("/foo/:id")
    func foo(
        id: Int,
        @Header one: String,
        @URLQuery @Validate(.between(18...99)) two: Int,
        three: Bool,
        request: Request
    ) async throws -> String {
        "Hello"
    }

    var _body: Route {
        Route(
            method: .POST,
            path: "/body",
            handler: { req in
                @Validate(.email) var thing = try req.content.thing.decode(String.self)
                try await $thing.validate()
                return body(thing: thing)
            }
        )
    }

    @POST("/body")
    func body(
        @Validate(.email) thing: String
    ) -> String {
        thing
    }

    @GET("/job")
    func job() async throws {
        try await $expensive(one: "", two: 1).dispatch()
    }

    @Job
    static func expensive(one: String, two: Int) async throws {
        print("Hello \(JobContext.current!.jobData.id)")
    }
}

@Controller
struct SomeController {
    @POST("/user", options: .stream)
    func test(
        @Validate(.email) name: String,
        @Validate(.between(18...99)) age: Int,
        @Validate(.password) password: String
    ) -> String { "test" }
}

extension Application {
    var queues: Queues {
        Queues(
            default: "memory",
            queues: [
                "memory": .memory,
            ]
        )
    }
}
