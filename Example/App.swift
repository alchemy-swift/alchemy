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

public struct ModelField: Identifiable {
    public var id: String { name }
    public let name: String
    public let type: Any.Type
    public let `default`: Any?

    public init<T>(_ name: String, type: T.Type, default: T? = nil) {
        self.name = name
        self.type = type
        self.default = `default`
    }
}

@Model
struct Todo {
    var id: Int
    let name: String
    var isDone: Bool = false
}

extension App {
    var queues: Queues {
        Queues(
            default: "memory",
            queues: [
                "memory": .memory,
            ]
        )
    }
}
