# Routing: Basics

- [Handling Requests](#handling-requests)
- [ResponseEncodable](#responseencodable)
  * [Anything `Codable`](#anything-codable)
  * [a `Response`](#a-response)
  * [`Void`](#void)
  * [Futures that result in a `ResponseConvertible` value](#futures-that-result-in-a-responseconvertible-value)
  * [Chaining Requests](#chaining-requests)
- [Controller](#controller)
- [Errors](#errors)
- [Path parameters](#path-parameters)
- [Accessing request data](#accessing-request-data)

## Handling Requests

When a request comes through the host & port on which your server is listening, it immediately gets routed to your application.

You can set up handlers in the `boot()` function of your app.

Handlers are defined with the `.on(method:at:handler:)` function, which takes an `HTTPMethod`, a path, and a handler. The handler is a closure that accepts a `Request` and returns a type that conforms to `ResponseConvertable`. There's sugar for registering handlers for specific methods via `get()`, `post()`, `put()`, `patch()`, etc.

```swift
struct ExampleApp: Application {
    func boot() {
        // GET {host}:{port}/hello
        get("/hello") { request in
            "Hello, World!"
        }
    }
}
```

## ResponseEncodable

Out of the box, Alchemy conforms most types you'd need to return from a handler to `ResponseConvertible`.

### Anything `Codable`

```swift
/// String
app.get("/string", handler: { _ in "Howdy!" })

/// Int
app.on(.GET, at: "/int", handler: { _ in 42 })

/// Custom type

struct Todo: Codable {
    var name: String
    var isDone: Bool
}

app.get("/todo", handler: { _ in 
    Todo(name: "Write backend in Swift", isDone: true)
})
```

### a `Response`

```swift
app.get("/response") { _ in 
    Response(status: .ok, body: HTTPBody(text: "Hello from /response"))
}
```

### `Void`

```swift 
app.get("/testing_query") { request in
    print("Got params \(request.queryItems)")
}
```

### Futures that result in a `ResponseConvertible` value

```swift
app.get("/todos") { _ in
    loadTodosFromDatabase()
}

func loadTodosFromDatabase() -> EventLoopFuture<[Todo]> {
    ...
}
```

*Note* an `EventLoopFuture<T>` is the Swift server world's version of a future. See [Under the Hood](12_UnderTheHood.md).

### Chaining Requests

To keep code clean, handlers are chainable.

```swift
let controller = UserController()
app
    .post("/user", handler: controller.create)
    .get("/user", handler: controller.get)
    .put("/user", handler: controller.update)
    .delete("/user", handler: controller.delete)
```

## Controller

For convenience, a protocol `Controller` is provided to help break up your route handlers. Implement the `route(_ app: Application)` function and register it in your `Application.boot`.

```swift
struct UserController: Controller {
    func route(_ app: Application) {
        app.post("/create", handler: create)
            .post("/reset", handler: reset)
            .post("/login", handler: login)
    }

    func create(req: Request) -> String {
        "Greetings from user create!"
    }

    func reset(req: Request) -> String {
        "Howdy from user reset!"
    }

    func login(req: Request) -> String {
        "Yo from user login!"
    }
}

struct App: Application {
    func boot() {
        ...
        controller(UserController())
    }
}
```

## Errors

Routing in Alchemy is heavily integrated with Swift's built in error handling. [Middleware](3b_RoutingMiddleware.md) & handlers allow for synchronous or asynchronous code to `throw`.

If an error is thrown or an `EventLoopFuture` results in an error, it will be caught & mapped to a `Response`.

Generic errors will result in an `Response` with a status code of 500, but if any error that conforms to `ResponseConvertible` is thrown, it will be converted as such. 

Out of the box `HTTPError` conforms to `ResponseConvertible`. If it is thrown, the response will contain the status code & message of the `HTTPError`.

```swift
struct SomeError: Error {}

app
    .get("/foo") { _ in
        // Will result in a 500 response with a generic error message.
        throw SomeError()
    }
    .get("/bar") { _ in
        // Will result in a 404 response with the custom message.
        throw HTTPError(status: .notFound, message: "This endpoint doesn't exist!")
    }
```

## Path parameters

Dynamic path parameters can be added with a variable name prefaced by a colon (`:`). The value will be parsed and accessible in the handler.

```swift
app.on(.GET, at: "/users/:userID") { req in
    let userID: String? = req.pathParameter(named: "userID")
}
```

As long as they have different names, a route can have as many path parameters as you'd like.

## Accessing request data

Data you might need to get off of an incoming request are in the `Request` type.

```swift
app.post("/users/:userID") { req in
    // Headers
    let authHeader: String? = req.headers.first(name: "Authorization")
    
    // Query (URL) parameters
    let countParameter: QueryParameter? = req.queryItems
        .filter ({ $0.name == "count" }).first

    // Path
    let thePath: String? = req.path

    // Path parameters
    let userID: String? = req.pathParameter(named: "userID")

    // Method
    let theMethod: HTTPMethod = req.method

    // Body
    let body: SomeCodable = try req.body.decodeJSON()
    
    // Token auth, if there is any
    let basicAuth: HTTPBasicAuth? = req.basicAuth()

    // Bearer auth, if there is any
    let bearerAuth: HTTPBearerAuth? = req.bearerAuth()
}
```

_Next page: [Routing: Middleware](3b_RoutingMiddleware.md)_

_[Table of Contents](/Docs#docs)_
