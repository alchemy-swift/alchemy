import Alchemy
import Collections

@Application
struct App {
    func boot() throws {
        use(UserController())
    }

    @POST("/hello")
    func helloWorld(email: String) -> String {
        "Hello, \(email)!"
    }

    @GET("/todos")
    func getTodos() async throws -> [Todo] {
        try await Todo.all()
    }

    @Job
    static func expensiveWork(name: String) {
        print("This is expensive!")
    }
}

@Controller
struct UserController {
    @HTTP("FOO", "/bar", options: .stream)
    func bar() {
        
    }

    @GET("/foo")
    func foo(field1: String, request: Request) -> Int {
        123
    }
}

@Model
struct Todo: Codable {
    var id: Int
    let name: String
    var isDone: Bool = false
}

extension App {
    var databases: Databases {
        Databases(
            default: "sqlite",
            databases: [
                "sqlite": .sqlite(path: "../AlchemyXDemo/Server/test.db")
            ]
        )
    }

    var queues: Queues {
        Queues(
            default: "memory",
            queues: [
                "memory": .memory,
            ]
        )
    }
}
