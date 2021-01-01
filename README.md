<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.3-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/joshuawright11/alchemy/releases"><img src="https://img.shields.io/github/release/joshuawright11/alchemy.svg" alt="Latest Release"></a>
<a href="https://github.com/joshuawright11/alchemy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/joshuawright11/alchemy.svg" alt="License"></a>
</p>

## About Alchemy

Alchemy is a Swift web framework for building the backend of your next mobile app. It makes your development experience...

- **Swifty**. Concise, expressive APIs built with the best parts of Swift.
- **Safe**. Swift is built for safety. Its typing, optionals, value semantics and error handling are leveraged throughout Alchemy to help protect you against thread safety issues, nil values and unexpected program state.
- **Rapid**. Write less code & rapidly develop full stack features, end to end. The CLI & supporting libraries (Papyrus, Fusion) are built around facilitating shared code & providing type safety between your server & iOS clients.
- **Easy**. With elegant syntax, 100% documentation, and guides touching on nearly every feature, Alchemy is designed to help you build backends faster, not get in the way.
- **Simple**. Juggle less Xcode projects by keeping your full stack Swift code in a monorepo containing your iOS app, Alchemy Server & Shared code. The CLI will help you get started.

## Code Samples
Alchemy is built to be both swifty and easy to follow. There's tons of examples in the [Guides](Documentation/0_GettingStarted.md) and [quickstart projects](Quickstart/) but here's a few examples.

### Hello, World!

```swift
import Alchemy

struct MyServerApp: Application {
    // The global app router
    @Inject router: Router

    func setup() {
        self.router.on(.post, at: "/hello") { request in
            "Hello, World!"
        }
    }
}

// main.swift
Launch<MyServerApp>.main()
```

### Databases & Rune ORM
Raw queries, a Query builder, and an ORM (Rune), are all provided for interacting with SQL databases.
```swift
import Alchemy

// Setup the default database.
DB.default = PostgresDatabase(
    DatabaseConfig(
        socket: .ip(host: "localhost", port: 5432),
        database: "alchemy",
        username: "admin",
        password: "password"
    )
)

// Create a model matching a table
struct Todo: Model {
    static var let tableName = "todos"

    var id: Int?
    let name: String
    let isDone: Bool
    
    @BelongsTo
    let user: User
}

// Query the model
Todo.query()
    .where("isDone" == false)
    .with(\.$user)
    .getAll()
    .whenSuccess { todos in
        for todo in todos {
            print("\(todo.user.name) hasn't finished \(todo.name)!")
        }
    }
```

### Using Papyrus to share network interfaces between iOS & server.
**Papyrus** helps you keep network interfaces type-safe across your Alchemy server & Swift clients. **Alchemy** provides first class support for providing & consuming Papyrus APIs. **iOS/macOS** clients can use **PapyrusAlamofire** for consuming Papyrus APIs.

First, define a shared interface for your API. Note the `@URLQuery` property wrapper tells API consumers to put `count` & `unfinishedOnly` in the query of the request. API providers will know to look for these values in the request query.
```swift
// MyProject/Shared/TodosAPI.swift
import Papyrus

public struct TodoDTO {
    public let id: Int
    public let name: String
    public let isDone: Bool 
    
    public init(...)
}

public struct TodosAPI: EndpointGroup {
    @GET("/todos")
    public var getAll: Endpoint<GetAllRequest, [TodoDTO]>

    public struct GetAllRequest: EndpointRequest {
        @URLQuery
        public let count: Int

        @URLQuery
        public let unfinishedOnly: Bool

        public init(...)
    }
}
```

Then, register this endpoint in your Alchemy server's router. Alchemy will automatically decode `GetAllRequest` from the incoming request & will enforce that the return type of the handler matches the expected return type of the endpoint, `[TodoDTO]`.
```swift
import Alchemy
import Shared

// MyProject/Server/MyApplication.swift
struct MyApplication: Application {
    @Inject router: Router

    func setup() {
        let todosAPI = TodosAPI()
        self.router.register(todosAPI.getAll) { (request: Request, endpointRequest: GetAllRequest)  in
            let isDone = endpointRequest.unfinishedOnly ? [false] : [true, false]
            return Todo.query()
                .where("isDone", in: isDone)
                .limit(endpointRequest.count)
                .getAll()
                .mapEach { TodoDTO(id: $0.id!, name: $0.name, isDone: $0.isDone) }
        }
    }
}
```

Finally, request the endpoint from your client. The request properties are automatically put in the right place and the `[TodoDTO]` response type is automatically parsed from the server response.
```swift
// MyProject/iOS/TodosView.swift
import PapyrusAlamofire
import Shared

let todosAPI = TodosAPI(baseURL: "http://localhost")
let requestData = TodosAPI.GetAllRequest(count: 50, unfinishedOnly: true)
todosAPI.getAll
    .request(GetAllRequest(count: 50, unfinishedOnly: true)) { (response: AFDataResponse<Data?>, todos: [TodoDTO]) in
        for todo in todos {
            print("Got todo: \(todo.name)")
        }
    }
```
Note that you can also use Papyrus to consume 3rd party APIs on both client _and_ server. Just create an interface for the APIs and request them.

### More Examples

Browse the [guides](Documentation/0_GettingStarted.md) for examples of advanced routing, .env files, complex queries, security & authentication, making http requests, database migrations & much more.

## Getting Started

### CLI

The Alchemy CLI is created to kickstart and accelerate development. We recommend using this to get your project going.

Download it with [Homebrew](https://brew.sh).
```shell
brew install alchemy
```
And create a new project. This will walk you through choosing a starter project.
```shell
alchemy new
```

### Manually

If you prefer not to use the CLI, you can clone a sample project full of example code from the [Quickstart directory](Quickstart/).

If you'd rather start with an empty slate, you can create a new Xcode project (likely a package) and add alchemy to the `Package.swift` file.
```swift
dependencies: [
    .package(url: "https://github.com/joshuawright11/alchemy", .branch("master"))
    ...
],
targets: [
    .target(name: "MySwiftServer", dependencies: [
        .product(name: "Alchemy", package: "alchemy"),
    ]),
]
```

### Adding `Papyrus` or `Fusion` to non-server targets
Papyrus (network interfaces) and Fusion (dependency injection) are built to work on both server and client (iOS, macOS, etc).

For server targets, they're included when you `import Alchemy`. For installation on client & shared targets, check out the [Fusion](Documentation/1b_ArchitectureServices.md) and [Papyrus](Documentation/3_Papyrus.md) guides.

## Documentation

### [Guides](Documentation/0_GettingStarted.md)
Reading the guides is the recommended way of getting up to speed. They provide a step by step walkthrough of just about everything Alchemy has to offer as well as essential core backend concepts for developers new to server side development.

**Note**: These guides are made to be followed by both people with backend experience and iOS devs with little to no backend experience. If something is confusing or difficult to understand please let us know on [Discord](https://discord.gg/Dnhh4yJe)!

### [API Reference](https://github.com/joshuawright11/alchemy/wiki)
The inline comments are extensive and full of examples. You can check it out in the codebase or a generated version on the [Github wiki](https://github.com/joshuawright11/alchemy/wiki).

### [Quickstart Code](https://github.com/joshuawright11/alchemy/tree/main/Quickstart)
If you'd rather just jump into reading some code, the projects in `Quickstart/` are contrived apps for the purpose of showing working, documented examples of everything Alchemy can do. You can clone them with `$ alchemy new` or browse through their code.

## Roadmap

Our top priorities right now are:

0. Conversion of async APIs from `EventLoopFuture` to [async/await](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md) as soon as it's released.
1. Filling in missing core server pieces. Particularly,
    - `HTTP/2` support
    - `SSL`/`TLS` support
    - Sending static files (html, css, js, images)
    - Built in support for `multipart/form-data` & `application/x-www-form-urlencoded`
2. A guide around deployment to various services.
3. Interfaces around Redis / Memcached.
4. A Swifty templating solution for sending back dynamic HTML pages.

## Contributing

- Ask **questions** on Stack Overflow with the tag `alchemy-swift`. You can also ask us in [Discord](https://discord.gg/Dnhh4yJe).
- Report **bugs** as an [issue on Github](https://github.com/joshuawright11/alchemy/issues/new) (ideally with a failing test case) or [Discord](https://discord.gg/CDZWAda3).
- Submit **feature requests** as an [issue on Github](https://github.com/joshuawright11/alchemy/issues/new) or bring them up on [Discord](https://discord.gg/9CZ4ksvn).

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to documentation, so don't be afraid to dive in and submit PRs for bug fixes, documentation cleanup, forks or tune ups.
