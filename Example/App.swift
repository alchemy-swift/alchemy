import Alchemy

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
        one: Header<String>,
        two: Int,
        three: Bool,
        request: Request
    ) async throws -> String {
        "Hello"
    }

    @POST("/body")
    func body(
        @Validate(.email) thing: Body<String>
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
