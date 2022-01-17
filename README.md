<p align="center"><a href="https://www.alchemyswift.com/"><img src="https://user-images.githubusercontent.com/6025554/132588005-5f8a6a94-ec15-4cab-9be9-1e90e86d374f.png" width="400"></a></p>

<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.5-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/alchemy-swift/alchemy/releases"><img src="https://img.shields.io/github/release/alchemy-swift/alchemy.svg" alt="Latest Release"></a>
<a href="https://github.com/alchemy-swift/alchemy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alchemy-swift/alchemy.svg" alt="License"></a>
</p>

> __Now fully `async/await`!__

Welcome to Alchemy, an elegant, batteries included backend framework for Swift. You can use it to build a production ready backend for your next mobile app, cloud project or website.

```swift
@main
struct App: Application {
    func boot() {
        get("/") { req in
            "Hello World!"
        }
    }
}
```

# About

Alchemy provides you with Swifty APIs for everything you need to build production-ready backends. It makes writing your backend in Swift a breeze by easing typical tasks, such as:

- [Simple, fast routing engine](https://www.alchemyswift.com/essentials/routing).
- [Powerful dependency injection container](https://www.alchemyswift.com/getting-started/services).
- Expressive, Swifty [database ORM](https://www.alchemyswift.com/rune-orm/rune).
- Database agnostic [query builder](https://www.alchemyswift.com/database/query-builder) and [schema migrations](https://www.alchemyswift.com/database/migrations).
- [Robust job queues backed by Redis or SQL](https://www.alchemyswift.com/digging-deeper/queues).
- First class support for [Plot](https://github.com/JohnSundell/Plot), a typesafe HTML DSL.
- [Supporting libraries to share typesafe backend APIs with Swift frontends](https://www.alchemyswift.com/supporting-libraries/papyrus).

## Why Alchemy?

Swift on the server is exciting but also relatively nascant ecosystem. Building a backend with it can be daunting and the pains of building in a new ecosystem can get in the way.

The goal of Alchemy is to provide a robust, batteries included framework with everything you need to build production ready backends. Stay focused on building your next amazing project in modern, Swifty style without sweating the details.

## Guiding principles

**1. Batteries Included**

With Routing, an ORM, advanced Redis & SQL support, Authentication, Queues, Cron, Caching and much more, `import Alchemy` gives you all the pieces you need to start building a production grade server app.

**2. Convention over Configuration**

APIs focus on simple syntax with lots of baked in convention so you can build much more with less code. This doesn't mean you can't customize; there's always an escape hatch to configure things your own way.

**3. Rapid Development**

Alchemy is designed to help you take apps from idea to implementation as swiftly as possible.

**4. Interoperability**

Alchemy is built on top of the lightweight, [blazingly](https://web-frameworks-benchmark.netlify.app/result?l=swift) fast [Hummingbird](https://github.com/hummingbird-project/hummingbird) framework. It is fully compatible with existing `swift-nio` and `vapor` components like [stripe-kit](https://github.com/vapor-community/stripe-kit), [soto](https://github.com/soto-project/soto) or [jwt-kit](https://github.com/vapor/jwt-kit) so that you can easily integrate with all existing Swift on the Server work.

**5. Keep it Swifty** 

Swift is built to write concice, safe and elegant code. Alchemy leverages it's best parts to help you write great code faster and obviate entire classes of backend bugs. With v0.4.0 and above, it's API is completely `async/await` meaning you have access to all Swift's cutting edge concurrency features.

# Get Started

To get started check out the extensive docs starting with [Setup](https://www.alchemyswift.com/getting-started/setup).

# Usage

The [Docs](Docs#docs) provide a step by step walkthrough of everything Alchemy has to offer. They also touch on essential core backend concepts for developers new to server side development. Below are some of the core pieces.

If you'd prefer to dive into some code, check out the example apps in the [alchemy-examples repo](https://github.com/alchemy-swift/alchemy-examples).

## Basics & Routing

Each Alchemy project starts with an implemention of the `Application` protocol. It has a single function, `boot()` for you to set up your app. In `boot()` you'll define your configurations, routes, jobs, and anything else needed to set up your application.

Routing is done with action functions `get()`, `post()`, `delete()`, etc on the application.

```swift
@main
struct App: Application {
    func boot() {
        post("/hello") { req in
            "Hello, \(req.query("name")!)!"
        }
    }
}
```

Route handlers can also be async using Swift 5.5's new concurrency features.

```swift
get("/download") { req in
    // Fetch an image from another site.
    try await Http.get("https://example.com/image.jpg")
}
```

Route handlers will automatically convert returned `Codable` types to JSON. You can also return a `Response` if you'd like full control over the returned content & it's encoding.

```swift
struct Todo: Codable {
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
        headers: ["Content-Type": "application/xml"],
        body: .data(xmlData)
    )
}
```

Bundling groups of routes together with controllers is a great way to clean up your code. This can help organize your projects by resource type.

```swift
struct TodoController: Controller {
    func route(_ app: Application) {
        app
            .get("/todo", getAllTodos)
            .post("/todo", createTodo)
            .patch("/todo/:id", updateTodo)
    }
    
    func getAllTodos(req: Request) async throws -> [Todo] { ... }
    func createTodo(req: Request) async throws -> Todo { ... }
    func updateTodo(req: Request) async throws -> Todo { ... }
}

// Register the controller
myApp.controller(TodoController())
```

## Environment variables

Often, you'll want to configure variables & secrets in your app's environment depending on whether your building for dev, stage or prod. The de facto method for this is a `.env` file, which Alchemy supports out of the box. 

Keys and values are defined per line, with an `=` separating them. Comments can be added with a `#.`

```shell
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

You can choose a custom env file by passing -e {env} or setting APP_ENV when running your program. The app will load it's environment from the file at `.env.{env}`.

## SQL queries

Alchemy comes with a powerful query builder that makes it easy to interact with SQL databases. You can always run raw queries as well. `DB` is a shortcut to injecting the default database.

```swift
try await DB.from("users").select("id").where("age" > 30)

try await DB.raw("SELECT * FROM users WHERE id = 1")
```

Most SQL operations are supported, including nested `WHERE`s and atomic transactions.

```swift
// The first user named Josh with age NULL or less than 28
try await DB.from("users")
    .where("name" == "Josh")
    .where { $0.whereNull("age").orWhere("age" < 28) }
    .first()

// Wraps all inner queries in an atomic transaction, will rollback if an error is thrown.
try await DB.transaction { conn in
    try await conn.from("accounts")
        .where("id" == 1)
        .update(values: ["amount": 100])
    try await conn.from("accounts")
        .where("id" == 2)
        .update(values: ["amount": 200])
}
```

## Rune ORM

To make interacting with SQL databases even simpler, Alchemy provides a powerful, expressive ORM called Rune. Built on Swift's Codable, it lets you make a 1-1 mapping between simple Swift types and your database tables. Just conform your types to Model and you're good to go. The related table name is assumed to be the type pluralized.

```swift
// Backed by table `users`
struct User: Model {
    var id: Int? 
    let firstName: String
    let lastName: String
    let age: Int
}

try await User(firstName: "Josh", lastName: "Wright", age: 28).insert()
```

You can easily query directly on your type using the same query builder syntax. Your model type is automatically decoded from the result of the query for you.

```swift
try await User.find(1)

// equivalent to

try await User.where("id" == 1).first()
```

If your database naming convention is different than Swift's, for example `snake_case` instead of `camelCase`, you can set the static `keyMapping` property on your Model to automatially convert to the proper case.

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
let todos = try await Todo.all().with(\.$user)
for todo in todos {
    print("\(todo.title) is owned by \(user.name)")
}
```

You can customize advanced relationship loading behavior, such as "has many through" by overriding the static `mapRelations()` function.

```swift
struct User: Model {
    @HasMany var workflows: [Workflow]
    
    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        mapper.config(\.$workflows).through("projects")
    }
}
```

## Middleware

Middleware lets you intercept requests coming in and responses coming out of your server. Use it to log, authenticate, or modify incoming `Request`s and outgoing `Response`s. Add one to your app with `use()` or `useAll()`.

```swift
struct LoggingMiddleware: Middleware {
    func intercept(_ request: Request, next: @escaping Next) async throws -> Response {
        let start = Date()
        let requestInfo = "\(request.head.method) \(request.path)"
        Log.info("Received request: \(requestInfo)")
        let response = try await next(request)
        let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
        Log.info("Sending response: \(response.status.code) \(requestInfo) after \(elapsedTime)")
        return response
    }
}

// Applies the Middleware to all subsequently defined handlers.
app.use(LoggingMiddleware())

// Applies the Middleware to all incoming requests & outgoing responses.
app.useAll(OtherMiddleware())
```

You may also add anonymous middlewares with a closure.

```swift
app.use { req, next -> Response in
    Log.info("\(req.method) \(req.path)")
    return next(req)
}
```

## Authentication

You'll often want to authenticate incoming requests using your database models. Alchemy provides out of the box middlewares for authorizing requests against your ORM models using Basic & Token based auth.

```swift
struct User: Model { ... }
struct UserToken: Model, TokenAuthable {
    var id: Int?
    let value: String

    @BelongsTo var user: User
}

app.use(UserToken.tokenAuthMiddleware())
app.get("/user") { req -> User in
    req.get(User.self) // The User is now accessible on the request
}
```

Note that to make things simple for you, a few things are happening under the hood. A `tokenAuthMiddleware()` is automatically available since `UserToken` conforms to `TokenAuthable`. This middleware automatically parse tokens from the `Authorization` header of incoming Requests and validates them against the `user_tokens` table. If the token matches a `UserToken` row, the related `User` and `UserToken` will be `.set()` on the Request for access via `get(User.self)`. If there is no match, your server will return a `401: Unauthorized` before hitting the handler.

Also note that, in this case, because `Model` descends from `Codable` you can return your database models directly from a handler to the client.

## Redis

Working with Redis is powered by the excellent [RedisStack](https://github.com/Mordil/RediStack) package. Once you register a configuration, the `Redis` type has most Redis commands, including pub/sub, as functions you can access.

```swift
Redis.bind(.connection("localhost"))

// Elsewhere
@Inject var redis: Redis

let value = redis.lpop(from: "my_list", as: String.self)

redis.subscribe(to: "my_channel") { val in
    print("got a \(val.string)")
}
```

If the function you want isn't available, you can always send a raw command. Atomic `MULTI`/`EXEC` transactions are supported with `.transaction()`.

```swift
try await redis.send(command: "GET my_key")

try await redis.transaction { redisConn in
    try await redisConn.increment("foo").get()
    try await redisConn.increment("bar").get()
}
```

## Queues

Alchemy offers `Queue` as a unified API around various queue backends. Queues allow your application to dispatch or schedule lightweight background tasks called `Job`s to be executed by a separate worker. Out of the box, `Redis`, relational databases, and memory backed queues are supported, but you can easily write your own provider by conforming to the `QueueProvider` protocol. 

To get started, configure the default `Queue` and `dispatch()` a `Job`. You can add any `Codable` fields to `Job`, such as a database `Model`, and they will be stored and decoded when it's time to run the job.

```swift
// Will back the default queue with your default Redis config
Queue.config(default: .redis())

struct ProcessNewUser: Job {
    let user: User
    
    func run() async throws {
        // do something with the new user
    }
}

try await ProcessNewUser(user: someUser).dispatch()
```

Note that no jobs will be dequeued and run until you run a worker to do so. You can spin up workers by separately running your app with the `queue` argument.

```shell
swift run MyApp worker
```

If you'd like, you can run a worker as part of your main server by passing the `--workers` flag.

```shell
swift run MyApp --workers 3
```

When a job is successfully run, you can optionally run logic by overriding the `finished(result:)` function on `Job`. It receives the `Result` of the job being run, along with any error that may have occurred. From `finished(result:)` you can access any of the jobs properties, just like in `run()`.

```swift
struct EmailJob: Job {
    let email: String

    func run() async throws { ... }

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

For advanced queue usage including channels, queue priorities, backoff times, and retry policies, check out the [Queues guide](https://www.alchemyswift.com/digging-deeper/queues).

## Scheduling tasks

Alchemy contains a built in task scheduler so that you don't need to generate cron entries for repetitive work, and can instead schedule recurring tasks right from your code. You can schedule code or jobs from the `scheudle()` method of your `Application` instance.

```swift
@main
struct MyApp: Application {
    ...

    func schedule(schedule: Scheduler) {
        // Say good morning every day at 9:00 am.
        schedule.run { print("Good morning!") }
            .daily(hour: 9)

        // Run `SendInvoices` job on the first of every month at 9:30 am.
        schedule.job(SendInvoices())
            .monthly(day: 1, hour: 9, min: 30)
    }
}
```

A variety of builder functions are offered to customize your schedule frequency. If your desired frequency is complex, you can even schedule a task using a cron expression.

```swift
// Every week on tuesday at 8:00 pm
schedule.run { ... }
    .weekly(day: .tue, hour: 20)

// Every second
schedule.run { ... }
    .secondly()

// Every minute at 30 seconds
schedule.run { ... }
    .minutely(sec: 30)

// At 22:00 on every day from Monday through Friday.”
schedule.run { ... }
    .cron("0 22 * * 1-5")
```

## ...and more!

Check out [the docs](https://www.alchemyswift.com/getting-started/setup) for more advanced guides on all of the above as well as [Migrations](https://www.alchemyswift.com/database/migrations), [Caching](https://www.alchemyswift.com/digging-deeper/cache), [Custom Commands](https://www.alchemyswift.com/digging-deeper/commands), [Logging](https://www.alchemyswift.com/essentials/logging), [making HTTP Requests](https://www.alchemyswift.com/digging-deeper/http-client), using the [HTML DSL](https://www.alchemyswift.com/essentials/views), advanced [Request](https://www.alchemyswift.com/essentials/requests) / [Response](https://www.alchemyswift.com/essentials/responses) usage, [typesafe APIs](https://www.alchemyswift.com/supporting-libraries/papyrus) between client and server, [deploying your apps to Linux or Docker](https://www.alchemyswift.com/getting-started/deploying), and more.

# Contributing

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to readable code and documentation, so feel free to dive in and contribute features, bug fixes, docs or tune ups.

You can report bugs, contribute features, or just say hi on [Github discussions](https://github.com/alchemy-swift/alchemy/discussions) and [Discord](https://discord.gg/74Bq29q22u).
