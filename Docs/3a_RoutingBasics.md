# Routing: Basics

## Handling Requests

When a request comes through the host & port on which your server is listening, it immediately gets routed into the `Router` registered to `Container.global`.

Access it via injection & register handlers to it, likely in the `setup()` of your `Application` type.

Handlers are defined with the `.on(method:at:do:)` function, which takes an `HTTPMethod`, a path, and a handler. The handler is a closure that accepts a `Request` and returns a `ResponseConvertable`.

```swift
struct ExampleApp: Application {
    @Inject var router: Router

    func setup() {
        self.router
            .on(.GET, at: "/hello") { request in 
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
router.on(.GET, at: "/string", do: { _ in "Howdy!" })

/// Int
router.on(.GET, at: "/int", do: { _ in 42 })

/// Custom type

struct Todo: Codable {
    var name: String
    var isDone: Bool
}

router.on(.GET, at: "/todo", do: { _ in 
    Todo(name: "Write backend in Swift", isDone: true)
})
```

### a `Response`

```swift
router.on(.GET, at: "/response") { _ in 
    Response(status: .ok, body: HTTPBody(text: "Hello from /response"))
}
```

### `Void`

```swift 
router.on(.GET, at: "/testing_query") { request in
    print("Got params \(request.queryItems)")
}
```

### an `EventLoopFuture<Void>` or `EventLoopFuture<T: Codable>`.

```swift
router.on(.GET, at: "/todos") { _ in
    self.loadTodosFromDatabase()
}

func loadTodosFromDatabase() -> EventLoopFuture<[Todo]> {
    ...
}
```

*Note* an `EventLoopFuture<T>` is the Swift server world's version of a `Future`. See [Architecture](1a_Architecture.md).

### Chaining Requests

To keep code clean, `.on` returns the router so requests can be chained.

```swift
let controller = UserController()
router
    .on(.POST, at: "/user", do: controller.create)
    .on(.GET, at: "/user", do: controller.get)
    .on(.PUT, at: "/user", do: controller.update)
    .on(.DELETE, at: "/user", do: controller.delete)
```

## Grouping requests

For convenience, requests can be grouped using the `.group(path: String, handler: ...)` function.

```swift
struct UserController {
    func create(req: HTTPRequest) -> String {
        "Greetings from user create!"
    }

    func reset(req: HTTPRequest) -> String {
        "Howdy from user reset!"
    }

    func login(req: HTTPRequest) -> String {
        "Yo from user login!"
    }
}

// Group all requests to /users
router.group(path: "/users") {
    let controller = UserController()

    $0.on(.POST, do: controller.create) // `POST /users`
    $0.on(.POST, at: "/reset", do: controller.reset) // `POST /users/reset`
    $0.on(.POST, at: "/login", do: controller.login) // `POST /users/login`
}
```

## Errors

Routing in Alchemy is heavily integrated with Swift's built in error handling. [Middleware](3b_RoutingMiddleware.md) & handlers allow for synchronous code to `throw`.

If an error is thrown or an `EventLoopFuture` results in an error, it will be caught & mapped to an `Response`.

Generic errors will result in an `Response` with a status code of 500, but if an `HTTPError` is thrown, the response will contain the status code & message of the error.

```swift
struct SomeError: Error {}

router
    .on(.GET, at: "/foo") { _ in
        // Will result in a 500 response with a generic error message.
        throw SomeError()
    }
    .on(.GET, at: "/bar") { _ in
        // Will result in a 404 response with the custom message.
        throw HTTPError(status: .notFound, message: "This endpoint doesn't exist!")
    }
```

## Path parameters

Dynamic path parameters can be added with a variable name prefaced by a colon (`:`). The value will be parsed and accessible in the handler.

```swift
router.on(.GET, at: "/users/:userID") { req in
    let userID: String? = req.pathParameter(named: "userID")
    ...
}
```

As long as they have different names, you can have as many path parameters as you need.

## Accessing request data

Data you might need to get off of an incoming request is in the `Request` type.

```swift
router.on(.POST, "/users/:userID") { req in
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

_[Table of Contents](/Docs)_