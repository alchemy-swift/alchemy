import Alchemy

@main
@Application
struct App {
    func boot() {
        Response.defaultEncoder = .json.with(keyMapping: .snakeCase)
        setDefaultDatabase(\.$database)
        setDefaultQueue(\.$queue)
        use(UserController())
    }

    @POST("/hello")
    func helloWorld(email: String) -> String {
        "Hello, \(email)!"
    }

    @GET("/todos")
    func getTodos() async throws -> [Todo] {
        try await Todo.all()
            .with(\.$hasOne.$hasOne)
            .with(\.$hasMany)
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
    var isDone = false
    let tags: [String]?

    @HasOne var hasOne: Todo
    @HasMany var hasMany: [Todo]
    @BelongsTo var belongsTo: Todo
    @BelongsToMany var belongsToMany: [Todo]
}

extension Todo {
    @HasOneThrough("through_table") var hasOneThrough: Todo
    @HasManyThrough("through_table") var hasManyThrough: [Todo]
    @BelongsToThrough("through_table") var belongsToThrough: Todo
}

extension Container {
    @Singleton var queue: Queue = isTest ? .memory : .database
    @Singleton var database: Database {
        guard !isTest else { return .memory }
        return .sqlite(path: "../../AlchemyXDemo/Server/test.db").logRawSQL()
    }
}
