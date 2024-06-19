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
        try await Todo.all().with(\.$todos)
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
struct Todo {
    var id: Int
    let name: String
    var isDone: Bool = false
    let tags: [String]?

    @HasMany var todos: [Todo]
}

extension App {
    var databases: Databases {
        Databases(
            default: "sqlite",
            databases: [
                "sqlite": .sqlite(path: "../AlchemyXDemo/Server/test.db").logRawSQL()
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
