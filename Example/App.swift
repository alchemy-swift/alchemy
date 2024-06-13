import Alchemy
import Papyrus

@Application
struct App {

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
    func body(thing: Body<String>) -> String {
        thing
    }

    @GET("/job")
    func job() async throws {
        try await App.$expensive(one: "", two: 1)
    }

    @Job 
    static func expensive(one: String, two: Int) async throws {
        print("Hello \(JobContext.current!.jobData.id)")
    }
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
