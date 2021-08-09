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

**1. Batteries Included**

With Routing, an ORM, advanced Redis & SQL support, Authentication, Cron, Caching and much more, `import Alchemy` gives you all the pieces you need to start building a production grade server app.

**2. Convention over Configuration**

APIs focus on simple syntax with lots of baked in convention so you can build much more with less code. This doesn't mean you can't customize; there's always an escape hatch to configure things your own way.

**3. Ease of Use** 

A fully documented codebase organized in a single repo make it easy to get building, extending and contributing.

**4. Keep it Swifty** 

Swift is built to write concice, safe and elegant code. Alchemy leverages it's best parts to help you write great code faster and obviate entire classes of backend bugs.

# Get Started

The Alchemy CLI is installable with [Mint](https://github.com/yonaskolb/Mint).

```shell
mint install alchemy-swift/cli@main
```

## Create a New App

Creating an app with the CLI will let you pick between a backend or fullstack (`iOS` frontend, `Alchemy` backend, `Shared` library) project. 

1. `alchemy new MyNewProject`
2. `cd MyNewProject` (if you selected fullstack, `MyNewProject/Backend`)
3. `swift run`
4. view your brand new app at http://localhost:8080

## Swift Package Manager

You can also add Alchemy to your project manually with the [Swift Package Manager](https://github.com/apple/swift-package-manager).

```swift
.package(url: "https://github.com/alchemy-swift/alchemy", .upToNextMinor(from: "0.2.0"))
```

Until `1.0.0` is released, minor version changes might be breaking, so you may want to use `upToNextMinor`.

# Usage

The [Docs](Docs#docs) provide a step by step walkthrough of everything Alchemy has to offer. They also touch on essential core backend concepts for developers new to server side development. Below are some of the core pieces.

## Basics & Routing

Each Alchemy project starts with an implemention of the `Application` protocol. It has a single function, `boot()` for you to set up your app. In `boot()` you'll define your configurations, routes, jobs, and anything else needed to set up your application.

Routing is done with action functions `get()`, `post()`, `delete()`, etc on the application.

```swift
@main
struct App: Application {
    func boot() {
        post("/say_hello") { req -> String in
            let name = req.query(for: "name")!
            return "Hello, \(name)!"
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

app.post("/json") { req -> Todo in
    return Todo(name: "Laundry", isComplete: false, created: Date())
}

app.get("/xml") { req -> Response in
    let xmlData = """
            <note>
                <to>Rachel</to>
                <from>Josh</from>
                <heading>Message</heading>
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

Choose what env file your app uses by setting APP_ENV, your program will load it's environment from the file at `.{APP_ENV} `.

## Services & DI

Alchemy makes DI a breeze to keep your services pluggable and swappable in tests. Most services in Alchemy conform to `Service`, a protocol built on top of [Fusion](https://github.com/alchemy-swift/fusion), which you can use to set sensible default configurations for your services.

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

In this way, you can easily configure as many `Database`s as you need while having Alchemy use the Postgres one by default. When it comes time for testing, injecting a mock service is easy.

```swift
final class MyTests: XCTestCase {
    func setup() {
        Queue.configure(default: .mock())
    }
}
```

Since Service wraps [Fusion](https://github.com/alchemy-swift/fusion), you can also access default and named configurations via the @Inject property wrapper. A variety of services can be set up and accessed this way including `Database`, `Redis`, `Router`, `Queue`, `Cache`, `HTTPClient`, `Scheduler`, `NIOThreadPool`, and `ServiceLifecycle`.

```swift
@Inject          var postgres: Database
@Inject("mysql") var mysql: Database
@Inject          var redis: Redis

postgres.rawQuery("select * from users")
mysql.rawQuery("select * from some_table")
redis.get("cached_data_key")
```

## SQL queries

Alchemy comes with a powerful query builder to make it easy to interact with SQL databases. You can always run raw SQL strings on a `Database` instance.

```swift
// Runs on Database.default
Query.from("users").select("id").where("age" > 30)

database.rawQuery("SELECT * FROM users WHERE id = 1")
```

Most SQL operations are supported, including nested `WHERE`s and atomic transactions.

```swift
// The first user named Josh with age NULL or less than 28
Query.from("users")
    .where("name" == "Josh")
    .where { $0.whereNull("age").orWhere("age" < 28) }
    .first()

// Wraps all inner queries in an atomic transaction.
database.transaction { conn in
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

To make interacting with SQL databases even easier, Alchemy provides a powerful, expressive ORM called Rune. Built on Swift's Codable, it lets you make a 1-1 mapping between simple Swift types and your database tables. Just conform your types to Model, add a static `tableName` property and you're good to go.

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

Middleware lets you intercept requests coming in and responses coming out of your server. You can use them to log, authenticate, or modify an incoming `Request` and outgoing `Response`. Add it to your app with `use()` or `useAll()`.

```swift
struct LoggingMiddleware: Middleware {
    func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response> {
        let start = Date()
        let requestInfo = "\(request.head.method.rawValue) \(request.path)"
         Log.info("Incoming Request: \(requestInfo)")
        return next(request)
            .map { response in
                let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
                Log.info("Outgoing Response: \(response.status.code) \(requestInfo) after \(elapsedTime)")
                return response
            }
    }
}

// Applies the Middleware to all subsequently defined handlers.
app.use(LoggingMiddleware())

// Applies the Middleware to all incoming requests & outgoing responses.
app.useAll(OtherMiddleware())
```

## Authentication

You'll often want to authenticate incoming requests using your database models. Alchemy provides out of the box middlewares for authing requests against your ORM models using Basic & Token based auth.

```swift
struct User: Model { ... }
struct UserToken: Model, TokenAuthable {
    static let tableName = "user_tokens"

    var id: Int?
    let value: String

    @BelongsTo var user: User
}

app.use(UserToken.tokenAuthMiddleware())
app.get("/user") { req -> User in
    let user = req.get(User.self)
    return user
}
```

Note that to make things simple for you, a few things are happening under the hood. A `tokenAuthMiddleware()` is automatically available since `UserToken` conforms to `TokenAuthable`. This middleware automatically parse tokens from the `Authorization` header of incoming Requests and validates them against the `user_tokens` table. If the token matches a `UserToken` row, the related `User` and `UserToken` will be `.set()` on the Request for access via `get(User.self)`. If there is no match, your server will return a `401: Unauthorized` before hitting the handler.

Also note that, in this case, because `Model` descends from `Codable` you can return your database models directly from a handler to the client.

## Redis

Working with Redis is powered by the excellent [RedisStack](https://github.com/Mordil/RediStack) package. Once you register a configuration, the `Redis` type has most Redis commands, including pub/sub, as functions you can access.

```swift
Redis.config(default: .connection("localhost"))

// Elsewhere
@Inject var redis: Redis

let value = redis.lpop(from: "my_list", as: String.self)

redis.subscribe(to: "my_channel") { val in
    print("got a \(val.string)")
}
```

If the function you want isn't available, you can always send a raw command. Atomic `MULTI`/`EXEC` transactions are supported with `.transaction()`.

```swift
redis.send(command: "GET my_key")

redis.transaction { redisConn in
    redisConn.increment("foo")
        .flatMap { _ in redisConn.increment("bar") }
}
```

## Queues

Alchemy offers `Queue` as a unified API around various queue backends. Queues allow your application to dispatch or schedule lightweight background tasks called `Job`s to be executed by a separate worker. Out of the box, `Redis` and relational databases are supported, but you can easily write your own driver by conforming to the `QueueDriver` protocol. 

To get started, configure the default `Queue` and `dispatch()` a `Job`. You can add any `Codable` fields to `Job`, such as a database `Model`, and they will be stored and decoded when it's time to run the job.

```swift
// Will back the default queue with your default Redis config
Queue.config(default: .redis())

struct ProcessNewUser: Job {
    let user: User
    
    func run() -> EventLoopFuture<Void> {
        // do something with the new user
    }
}

ProcessNewUser(user: someUser).dispatch()
```

Note that no jobs will be dequeued and run until you run a worker to do so. You can spin up workers by separately running your app with the `queue` argument.

```shell
swift run MyApp queue
```

If you'd like, you can run a worker as part of your main server by passing the `--workers` flag.

```shell
swift run MyApp --workers 3
```

When a job is successfully run, you can optionally run logic by overriding the `finished(result:)` function on `Job`. It receives the `Result` of the job being run, along with any error that may have occurred. From `finished(result:)` you can access any of the jobs properties, just like in `run()`.

```swift
struct EmailJob: Job {
    let email: String

    func run() -> EventLoopFuture<Void> { ... }

    func finished(result: Result<Void, Error>) {
        switch result {
        case .failure(let error):
            Log.error("failed to send an email to \(email)!")
        case .success:
            Log.info("successfully sent an email to \(email)!")
        }
    }
}
```

For advanced queue usage including channels, queue priorities, backoff times, and retry policies, check out the guide on Queues.


## Scheduling tasks

Alchemy contains a built in task scheduler so that you don't need to generate cron entries for repetitive work, and can instead schedule recurring tasks right from your code. You can schedule code or jobs from your `Application` instance.

```swift
// Say good morning every day at 9:00 am.
app.schedule { print("Good morning!") }
    .daily(hour: 9)

// Run `SendInvoices` job on the first of every month at 9:30 am.
app.schedule(job: SendInvoices())
    .monthly(day: 1, hour: 9, min: 30)
```

A variety of builder functions are offered to customize your schedule frequency. If your desired frequency is complex, you can even schedule a task using a cron expression.

```swift
// Every week on tuesday at 8:00 pm
app.schedule { ... }
    .weekly(day: .tue, hour: 20)

// Every second
app.schedule { ... }
    .secondly()

// Every minute at 30 seconds
app.schedule { ... }
    .minutely(sec: 30)

// At 22:00 on every day-of-week from Monday through Friday.”
app.schedule { ... }
    .cron("0 22 * * 1-5")
```

## ...and more!

Check out the docs for more advanced guides on all of the above as well as Migrations, Caching, Logging, making HTTP Requests, using the HTML DSL, advanced Request / Response, sharing API interfaces between client and server, deploying your apps to production, and much more.

# Contributing

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to readable code and documentation, so feel free to dive in and contribute features, bug fixes, docs or tune ups.

You can report bugs, contribute features, or just say hi on [Github discussions](https://github.com/alchemy-swift/alchemy/discussions) and [Discord](https://discord.gg/74Bq29q22u).