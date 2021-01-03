<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.3-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/joshuawright11/alchemy/releases"><img src="https://img.shields.io/github/release/joshuawright11/alchemy.svg" alt="Latest Release"></a>
<a href="https://github.com/joshuawright11/alchemy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/joshuawright11/alchemy.svg" alt="License"></a>
</p>

## About Alchemy

Alchemy is a batteries included Swift web framework. It's designed to make your development experience...

- **Smooth**. Elegant syntax, 100% documentation, and extensive guides touching on every feature. Alchemy is designed to help you build backends faster, not get in the way.
- **Simple**. Context-switch less by writing full stack Swift. Keep the codebase simple with all your iOS, server, and shared code in a single Xcode workspace.
- **Rapid**. Quickly develop full stack features, end to end. Write less code by using supporting libraries ([Papyrus](Docs/4_Papyrus.md), [Fusion](Docs/2_Fusion.md)) to shared code & providing type safety between your server & iOS/macOS clients.
- **Safe**. Swift is built for safety. Its typing, optionals, value semantics and error handling are leveraged throughout Alchemy to help protect you against thread safety issues, nil values and unexpected program state.
- **Swifty**. Concise, expressive APIs built with the best parts of Swift.

## What's can it do?

Out of the box, Alchemy includes...

- Simple, fast routing.
- Powerful dependency injection.
- Expressive ORM and query builder.
- Database agnostic schema migrations.
- Cron-like job scheduling.
- Sending APNS (push notifications).
- Supporting libraries for defining type safe APIs between Swift clients & server. 
- 100% API docs, extensive guides, quickstart projects
- Env file support, customizable middleware, non-blocking APIs for heavy work loads, authentication middleware, and more

## Code Samples
There is tons of sample code in the [**guides**](Documentation/) and [**quickstart projects**](Quickstart/) but here are a few examples.

### Hello, World!

```swift
import Alchemy

struct MyServerApp: Application {
    // Inject the global app router
    @Inject router: Router

    func setup() {
        self.router.on(.get, at: "/hello") { request in
            "Hello, World!"
        }
    }
}

// main.swift
Launch<MyServerApp>.main()
```

### Databases & Rune ORM
Rune, the ORM, is built on top of Swift's Codable, making database querying a cinch.
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
    static let tableName = "todos"

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

### Type safe networking interfaces between client and server.
**Papyrus**, and IDL-like network layer, helps you keep network interfaces type-safe across your Alchemy server & Swift clients. **Alchemy** provides first class support for providing _and_ consuming Papyrus APIs. **iOS/macOS** clients can use **PapyrusAlamofire** for consuming Papyrus APIs.

---

First, define a shared interface for your API. Note the `@URLQuery` property wrapper tells API consumers and producers that `count` & `unfinishedOnly` belong in the query of the request. This info allows for automatic request "encoding" & "decoding" from clients and servers.
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

Then, register this endpoint in your Alchemy server's router. Alchemy will automatically decode `GetAllRequest` from the right spots in the incoming request & will enforce that the return type of the handler matches the expected return type of the endpoint, `[TodoDTO]`.
```swift
import Alchemy
import Shared

// MyProject/Server/MyApplication.swift
struct MyApplication: Application {
    @Inject router: Router

    func setup() {
        let todosAPI = TodosAPI()
        self.router.register(todosAPI.getAll) { request, endpointRequest in
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

Finally, request the endpoint from your client. The request properties are automatically put in the query because of the `@URLQuery` wrappers and the `[TodoDTO]` response type is automatically parsed from the server's response.
```swift
// MyProject/iOS/TodosView.swift
import PapyrusAlamofire
import Shared

let todosAPI = TodosAPI(baseURL: "http://localhost")
let requestData = TodosAPI.GetAllRequest(count: 50, unfinishedOnly: true)
todosAPI.getAll
    .request(requestData) { response, todos in
        for todo in todos {
            print("Got todo: \(todo.name)")
        }
    }
```
Note that you can also use Papyrus to consume 3rd party APIs on both client _and_ server. Just create an interface for the APIs and request them.

### More Examples

Browse the [guides](Documentation/0_GettingStarted.md) for examples of advanced routing, `.env` files, complex queries, security & authentication, making http requests, database migrations & much more.

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

**Note**: If something is confusing or difficult to understand please let us know on [Discord](https://discord.gg/Dnhh4yJe)!

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
