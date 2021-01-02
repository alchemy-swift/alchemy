# Routing: Basics

Alchemy has built in support for routing incoming HTTP REST requests. Routing happens through a singleton `HTTPRouter` class.

Access it via injection & register routes to it, likely in the `setup()` of your `Application` type.

```swift
struct ExampleApp: Application {
    // HTTPRouter conforms to SingletonService so can be used 
    // with @Inject out of the box.
    @Inject var router: HTTPRouter
    ...

    func setup() {
        ...
        self.router
            .on(.GET, at: "/hello", do: { request in "Howdy!" })
    }
}
```

## Routing requests

The router comes with a variety of functions to help you route all incoming `REST` requests, including the demonstrated `.on(method:at:do:)`.

Pass it an `HTTPMethod`, a path, and a handler. The handler takes an HTTPRequest and must return something that conforms to `HTTPResponseEncodable`. 

Out of the box, Alchemy conforms most types you'd need to return from a handler to `HTTPResponseEncodable` including...

...Anything `Codable`
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

...`Void`

```swift 
router.on(.GET, at: "/testing_query") { request in
    print("Got params \(request.queryItems)")
}
```

...an `EventLoopFuture<Void>` or `EventLoopFuture<T: Codable>`.

```swift
router.on(.GET, at: "/todos") { _ in
    self.loadTodosFromDatabase()
}

func loadTodosFromDatabase() -> EventLoopFuture<[Todo]> {
    ...
}
```

*Note*

An `EventLoopFuture<T>` is the Swift server world's version of a `Future`. It represents an asynchronous operation that hasn't yet completed, but will complete with either an `Error` or a value of `T`. It comes from [swift-nio]().

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

    // `POST /users`
    $0.on(.POST, do: controller.create)

    // `POST /users/reset`
    $0.on(.POST, at: "/reset", do: controller.reset)

    // `POST /users/login`
    $0.on(.POST, at: "/login", do: controller.login)
}
```

## Errors

Routing in Alchemy is heavily integrated with Swift's built in error handling. Middleware & handler functions & closures allow for synchronous code to `throw`.

If an error is thrown either synchronously or asynchronously through an `EventLoopFuture`, it will be caught & mapped to an `HTTPResponse`.

Generic errors will result in an `HTTPResponse` with a status code of 500, but if an `HTTPError` is thrown, the response will contain the status code & message of the error.

```swift
struct SomeError: Error {}

router
    .on(.GET, "/foo", { _ in
        // Will result in a 500 response with a generic error message.
        throw SomeError()
    })
    .on(.GET, "/bar", { _ in
        // Will result in a 404 response with the custom message.
        throw HTTPError(status: .notFound, message: "This endpoint doesn't exist!")
    })
```

## Path parameters

Dynamic path parameters can be added with a variable name prefaced by a colon. The value of that request can be resolved in the handler from the HTTPRequest object.

```swift
router.on(.GET, "/users/:userID") { req in
    let userID: String? = req.pathParameter(named: "userID")
    ...
}
```

As long as they have different names, you can have as many path parameters as you need.

## Accessing request data

Data you might need to get off of an incoming request is in the `HTTPRequest` type. While not exhaustive, below are some common use cases.

```swift
router.on(.POST, "/users") { req in
    // Headers
    let authHeader: String? = req.headers.first(name: "Authorization")
    
    // Query (URL) parameters
    let countParameter: QueryParameter? = req.queryItems
        .filter ({ $0.name == "count" }).first

    // Path
    let thePath: String? = req.path

    // Path parameters
    //
    // (Assume registered path was `/users/:userID`)
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