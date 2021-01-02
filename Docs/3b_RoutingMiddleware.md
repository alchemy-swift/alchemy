# Routing: Middleware

## Middleware

A middleware is a bit of code that is run before a request is handled. It may or may not modify the request.

In Alchemy, a middleware is created by conforming to the `Middleware` protocol. This has a single function, `intercept` that takes an `HTTPRequest` & returns an `EventLoopFuture<HTTPRequest>`.

```swift
/// Logs all requests that come through this middleware.
struct LoggingMiddleware: Middleware {
    func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
        Log.info("Got a request to \(request.path).")
        // `intercept` returns an EventLoopFuture<HTTPRequest>, in case your 
        // middleware needs to do something asynchronously before returning.
        //
        // If the operation is synchronous, just create a new `EventLoopFuture`
        // given the `eventLoop` of the current request.
        return .new(request)
    }
}
```

Middleware can be setup to intercept requests via the router.

```swift
router
    .on(.POST, at: "/password_reset", do: ...)
    // Because this middleware is provided after the /password_reset endpoint,
    // it will only affect subsequent routes. In this case, only requests to 
    // `/user` and `/todos` would be intercepted by the LoggingMiddleware.
    .middleware(LoggingMiddleware())
    .on(.GET, at: "/user", do: ...)
    .on(.GET, at: "/todos", do: ...)
```

Sometimes you may want a Middleware to add some data to an `HTTPRequest`. You can easily do this using the `.set` function on `HTTPRequest` and then accessing the data via `.get` in a handler further along the request chain.

```swift
// For example, you might be doing some homegrown AB testing...

struct ExperimentMiddleware {
    func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
        let config: ExperimentConfig = ...
        return .new(request.set(config))
    }
}

...

router
    .middleware(ExperimentalMiddleware())
    .on(.GET, "/experimental_endpoint") { request in
        // .get() will throw an error if a value with that type doesn't exist.
        let config: ExperimentConfig = try request.get()
        if config.shouldUseForcefulCopy {
            return "HELLO WORLD!!!!!"
        } else {
            return "hello world"
        }
    }
```

There's also a `.group` function that takes a Middleware.

```swift
router
    .on(.POST, at: "/user", do: ...)
    .group(middleware: CustomAuthMiddleware()) {
        // Each of these endpoints will be protected by the
        // `CustomAuthMiddleWare`...
        $0.on(.GET, at: "/todo", do: ...)
            .on(.PUT, at: "/todo", do: ...)
            .on(.DELETE, at: "/todo", do: ...)
    }
    // ...but this one will not. 
    .on(.POST, at: "/reset", do: ...)
```

## Global middlewares

By default, a middleware will only intercept requests that come after it in a handler chain.

```swift
router
    .middleware(LoggingMiddleware())
    .on(.POST, at: "/foo", do: ...)
    .on(.POST, at: "/bar", do: ...)

router
    .on(.POST, at: "/foo", do: ...)

// The LoggingMiddleware will intercept `/foo` & `/bar` but not `/baz`.
```

If you'd like to apply a middleware to ALL incoming requests from the global `Router`, you can do so with the `GlobalMiddlewares` type. It's a singleton & can be injected with `Fusion`.

```swift
struct ExampleApp: Application {
    @Inject var router: HTTPRouter
    @Inject var globalMiddlewares: GlobalMiddlewares
    ...

    func setup() {
        // LoggingMiddleware will intercept all requests that go through thes
        // global `HTTPRouter`.
        //
        // TODO: `router.globalMiddleware()` instead?
        self.globalMiddlewares.add(LoggingMiddleware())
        
        self.router
            // LoggingMiddleware will be applied to all of these.
            .on(.GET, at: "/foo", do: { request in "Howdy!" })
            .on(.POST, at: "/bar", do: { request in "Howdy!" })
            .on(.PUT, at: "/baz", do: { request in "Howdy!" })
    }
}
```

_Next page: [Papyrus](4_Papyrus.md)_

_[Table of Contents](/Docs)_