<p align="center"><img src="https://user-images.githubusercontent.com/6025554/104392567-3226f000-54f7-11eb-9ad6-b8795764aace.png" width="400"></a></p>

<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.4-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/alchemy-swift/alchemy/releases"><img src="https://img.shields.io/github/release/alchemy-swift/alchemy.svg" alt="Latest Release"></a>
<a href="https://github.com/alchemy-swift/alchemy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alchemy-swift/alchemy.svg" alt="License"></a>
</p>

Welcome to Alchemy, an elegant, batteries included backend framework for Swift. You can use it to build a production ready backend for your next mobile app, cloud project or website.

```swift
@main 
struct App: Application {
    func boot() {
        get("/hello") { req in
            "Hello World!"
        }
    }
}
```

# About

Alchemy provides you with Swifty APIs for everything you need to build production-ready backends. It makes writing your backend in Swift a breeze by easing typical tasks, such as:

- Simple, fast **routing engine**.
- Powerful **dependency injection** container.
- Expressive, Swifty database ORM.
- Database agnostic query builder and schema **migrations**.
- Robust job queues backed by Redis or SQL.
- First class support for [Plot](https://github.com/JohnSundell/Plot), a typesafe HTML DSL.
- Supporting libraries to share typesafe backend APIs with Swift frontends.

## Why Alchemy?

Swift on the server is exciting but also relatively nascant ecosystem. Building a backend with it can be daunting and the pains of building in a new ecosystem (navigating piecemeal projects, sparse feature sets, incomplete documentation) can get in the way.

The goal of Alchemy is to provide a robust, batteries included framework with everything you need to build production ready backends. Stay focused on building your next amazing project in modern, Swifty style without sweating the details.

## Guiding principles

- **Batteries included**: With Routing, an ORM, advanced Redis & SQL support, Authentication, Cron, Caching and much more, `import Alchemy` gives you all the pieces you need to start building a production grade server app.
- **Convention over configuration**: APIs focus on simple syntax with lots of baked in convention so you can build much more with less code. This doesn't mean you can't customize; there's always an escape hatch to configure things your own way.
- **Ease of use**: A fully documented codebase organized in a single repo make it easy to get building, extending and contributing.
- **Keep it Swifty**: *Fully `async/await`*! Swift is built to write concice, safe and elegant code. Alchemy leverages it's best parts to help you write great code faster and obviate entire classes of backend bugs.

# Get Started

## Install Alchemy

The Alchemy CLI is installable with [Mint](https://github.com/yonaskolb/Mint).

```shell
mint install alchemy-swift/cli@main
```

## Create a New App

Creating an app with the CLI will let you pick between a backend or a fullstack (`iOS` frontend, `Alchemy` backend, `Shared` library) project. 

1. `alchemy new MyNewProject`
2. `cd MyNewProject` (if you selected fullstack, `MyNewProject/Backend`)
3. `swift run`
4. view your brand new app at http://localhost:8080

When you're ready to ship, check out the [deployment guide](Docs/9_Deploying.md) for deploying to Linux or Docker.

## Swift Package Manager

You can also add Alchemy to your project manually with the [Swift Package Manager](https://github.com/apple/swift-package-manager). Until `1.0.0` is released, minor version changes might be breaking, so you may want to use `upToNextMinor`.

```swift
.package(url: "https://github.com/alchemy-swift/alchemy", .upToNextMinor(from: "0.2.0"))
```

# Usage

The [Docs](Docs#docs) provide a step by step walkthrough of everything Alchemy has to offer. They also touch on essential core backend concepts for developers new to server side development. Below are some of the core pieces.

## Getting started

Each Alchemy project starts with an implemention of the `Application` protocol. It has a single `boot()` for you to set up your app. In `boot()` you'll define your configurations, routes, jobs, and anything else needed to set up your application.

Routing is done with action functions `get()`, `post()`, `delete()`, etc on the application.

```swift
@main
struct App: Application {
    func boot() {
        get("/hello") { req in
            return "Hello, World!"
        }

        post("/say_hello") { req -> String in
            let name = req.query(for: "name")!
            return "Hello, \(name)"
        }
    }
}
```

Route handlers will automatically convert returned Swift.Codable types to JSON. You can also return a `Response` if you'd like full control over the returned content & it's encoding.

```swift
struct Todo {
    let name: String
    let isComplete: Bool
    let created: Date
}

post("/json") { req -> Todo in
    return Todo(name: "Laundry", isComplete: false, created: Date())
}

get("/xml") { req -> Response in
    let xmlData = """
            <note>
                <to>Rachel</to>
                <from>Josh</from>
                <heading>Reminder</heading>
                <body>Hello from XML!</body>
            </note>
            """.data(using: .utf8)!
    return Response(
        status: .accepted,
        headers: ["Some-Header": "value"],
        body: HTTPBody(data: xmlData, mimeType: .xml)
    )
}
```

Bundling groups of routes together with controllers can be a great way to clean up your code. This can help organize your projects by resource type.

```swift
struct TodoController: Controller {
    func route(_ app: Application) {
        app
            .get("/todo", getAllTodos)
            .post("/todo", createTodo)
            .patch("/todo/:id", updateTodo)
    }
    
    func getAllTodos(req: Request) -> [Todo] {
        ...
    }
    
    func createTodo(req: Request) -> Todo {
        ...
    }
    
    func updateTodo(req: Request) -> Todo {
        ...
    }
}

// Register the controller
myApp.controller(TodoController())
```

## Environment variables

Often, you'll want to configure variables & secrets in your app's environment depending on whether your building for dev, stage or prod. The de facto method for this is a `.env` file, which Alchemy supports out of the box. 

Keys and values are defined per line, with an `=` separating them. Comments can be added with a `#.`

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB=alchemy
DB_USER=prod
DB_PASSWORD=eLnGRkw55mHEssyP
```

You can access these variables in your code through the `Env` type. If you're feeling fancy, `Env` supports dynamic member lookup.

```swift
let dbHost: String = Env.current.get("DB_HOST")!
let dbPort: Int = Env.current.get("DB_PORT")!
let isProd: Bool = Env.current.get("IS_PROD")!

let db: String = Env.DB_DATABASE
let dbUsername: String = Env.DB_USER
let dbPass: String = Env.DB_PASS
```

## Services & DI

Alchemy makes DI a breeze to make your services easily pluggable and swappable in tests. Most services conform to  `Service`, built on top of [Fusion](https://github.com/alchemy-swift/fusion), which you can use to set sensible default instances for your services.

You can use `Service.config(default: ...)` to configure the default instance of a service for the app. `Service.configure("key", ...)` lets you configure another, named instance. Most functions that interact with a `Service`, will default to running on your `Service`'s default configuration.

```swift
// Set the default database for the app.
Database.config(
    default: .postgres(
        host: "localhost",
        database: "alchemy",
        username: "user",
        password: "password"
    )
)

// Set the database identified by the "mysql" key.
Database.config("mysql",  .mysql(host: "localhost", database: "alchemy"))

// Get's all `User`s from the default Database (postgres).
Todo.all()

// Get's all `User`s from the "mysql" database.
Todo.all(db: .named("mysql"))
```

In this way, you can easily configure as many `Database`s as you need while having Alchemy use the Postgres one by default. When it comes time for testing, injecting a mock database is dead simple.

```swift
final class MyTests: XCTestCase {
    func setup() {
        Database.configure(default: .mock())
    }
}
```

A variety of services are set up and accessed this way including `Database`, `Redis`, `Router`, `Queue`, `Cache`, `HTTPClient`, `Scheduler`, `NIOThreadPool`, and `ServiceLifecycle`.

## SQL queries

Alchemy comes with a powerful query builder to make it easy to interact with SQL databases. You can always run raw SQL strings on a `Database` instance.

```swift
// Runs on Database.default
Query.from("users").select("id").where("age" > 30)

Database.default.rawQuery("SELECT * FROM users WHERE id = 1")
```

Most SQL operations are supported, including nested `WHERE`s and atomic transactions.

```swift
// The first user named Josh with age NULL or less than 28
Query.from("users")
    .where("name" == "Josh")
    .where { $0.whereNull("age").orWhere("age" < 28) }
    .first()

// Wraps all inner queries in an atomic transaction.
Database.default.transaction { conn in
    conn.query()
        .where("account" == 1)
        .update(values: ["amount": 100])
        .flatMap { _ in
            conn.query()
                .where("account" == 2)
                .update(values: ["amount": 200])
        }
}
```

## Rune ORM

To make interacting with SQL databases even easier, Alchemy provides a powerful, expressive ORM called Rune. Built on Swift's Codable it lets you make a 1-1 mapping between simple Swift types and your database tables. Just conform your types to Model and you're good to go.

```swift
struct User: Model {
    static let tableName = "users"

    var id: Int? 
    let firstName: String
    let lastName: String
    let age: Int
}

let newUser = User(firstName: "Josh", lastName: "Wright", age: 28)
newUser.insert()
```

You can easily query directly on your type using the same query builder syntax. Your model type is automatically decoded from the result of the query for you.

```swift
User.where("id" == 1).firstModel()
```

If your database naming convention is different than Swift's, for example `snake_case`, you can set the static `keyMapping` property on your Model to automatially convert from Swift `camelCase`.

```swift
struct User: Model {
    static var keyMapping: DatabaseKeyMapping = .convertToSnakeCase
    ...
}
```

Relationships are defined via property wrappers & can be eager loaded using `.with(\.$keyPath)`.

```swift
struct Todo: Model {
    ...

    @BelongsTo var user: User
}

// Queries all `Todo`s with their related `User`s also loaded.
Todo.all().with(\.$user)
```

## Middleware

## Authentication

## Redis & caching

## Queues

## Scheduling tasks

# Contributing

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to readable code and documentation, so don't be afraid to dive in and submit PRs for bug fixes, documentation cleanup, forks or tune ups!

You can report bugs, contribute features, or just say hi on [Github discussions](https://github.com/alchemy-swift/alchemy/discussions) and [Discord](https://discord.gg/74Bq29q22u).