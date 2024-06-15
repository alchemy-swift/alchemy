import Alchemy

extension Router {
    @discardableResult func use(_ route: Route) -> Self {
        on(route.method, at: route.path, options: route.options, use: route.handler)
        return self
    }
}

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
        self.handler = { req in
            try await handler(req)
            return Response(status: .ok)
        }
    }

    init<E: Encodable>(method: HTTPMethod, path: String, options: RouteOptions = [], handler: @escaping (Request) async throws -> E) {
        self.method = method
        self.path = path
        self.options = options
        self.handler = { req in
            let value = try await handler(req)
            if let convertible = value as? ResponseConvertible {
                return try await convertible.response()
            } else {
                return try Response(status: .ok, encodable: value)
            }
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

    @GET("/foo")
    func foo() -> Bool { .random() }
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
