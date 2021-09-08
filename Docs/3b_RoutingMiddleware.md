# Routing: Middleware

- [Creating Middleware](#creating-middleware)
  * [Accessing the `Request`](#accessing-the-request)
  * [Setting Data on a Request](#setting-data-on-a-request)
  * [Accessing the `Response`](#accessing-the--response-)
- [Adding Middleware to Your Application](#adding-middleware-to-your-application)
  * [Global Intercepting](#global-intercepting)
  * [Specific Intercepting](#specific-intercepting)

## Creating Middleware

A middleware is a piece of code that is run before or after a request is handled. It might modify the `Request` or `Response`.

Create a middleware by conforming to the `Middleware` protocol. It has a single function `intercept` which takes a `Request` and `next` closure. It returns an `EventLoopFuture<Response>`.

### Accessing the `Request`

If you'd like to do something with the `Request` before it is handled, you can do so before calling `next`. Be sure to call and return `next` when you're finished!

```swift
/// Logs all requests that come through this middleware.
struct LogRequestMiddleware: Middleware {
    func intercept(_ request: Request, next: @escaping Next) -> EventLoopFuture<Response> {
        Log.info("Got a request to \(request.path).")
        return next(request)
    }
}
```

You may also do something with the request asynchronously, just be sure to continue the chain with `next(req)` when you are finished.

```swift
/// Runs a database query before passing a request to a handler.
struct QueryingMiddleware: Middleware {
    func intercept(_ request: Request, next: @escaping Next) -> EventLoopFuture<Response> {
        return User.all()
            .flatMap { users in 
                // Do something with `users` then continue the chain
                next(request)
            }
    }
}
```

### Setting Data on a Request

Sometimes you may want a `Middleware` to add some data to a `Request`. For example, you may want to authenticate an incoming request with a `Middleware` and then add a `User` to it for handlers down the chain to access. 

You can set generic data on a `Request` using `Request.set` and then access it in subsequent `Middleware` or handlers via `Request.get`.

For example, you might be doing some experiments with a homegrown `ExperimentConfig` type. You'd like to assign random configurations of that type on a per-request basis. You might do so with a `Middleware`:

```swift
struct ExperimentMiddleware: Middleware {
    func intercept(_ request: Request, next: @escaping Next) -> EventLoopFuture<Response> {
        let config: ExperimentConfig = ... // load a random experiment config
        return next(request.set(config))
    }
}
```

You would then intercept requests with that `Middleware` and utilize the set `ExperimentConfig` in your handlers.

```swift
app
    .use(ExperimentalMiddleware())
    .get("/experimental_endpoint") { request in
        // .get() will throw an error if a value with that type hasn't been `set()` on the `Request`.
        let config: ExperimentConfig = try request.get()
        if config.shouldUseLoudCopy {
            return "HELLO WORLD!!!!!"
        } else {
            return "hey, world."
        }
    }
```

### Accessing the `Response`

If you'd like to do something with the `Response` of the handled request, you can plug into the future returned by `next`.

```swift
/// Logs all responses that come through this middleware.
struct LogResponseMiddleware: Middleware {
    func intercept(_ request: Request, next: @escaping Next) -> EventLoopFuture<Response> {
        return next(request)
            // Use `flatMap` if you want to do something asynchronously.
            .map { response in
                Log.info("Got a response \(response.status) from \(request.path).")
                return response
            }
    }
}
```

## Adding Middleware to Your Application

There are a few ways to have a `Middleware` intercept requests.

### Global Intercepting

If you'd like a middleware to intercept _all_ requests on an `Application`, you can add it via `Application.useAll`.

```swift
struct ExampleApp: Application {
    func boot() {
        self
            .useAll(LoggingMiddleware())
            // LoggingMiddleware will intercept all of these, as well as any unhandled requests.
            .get("/foo") { request in "Howdy foo!" }
            .post("/bar") { request in "Howdy bar!" }
            .put("/baz") { request in "Howdy baz!" }
    }
}
```

### Specific Intercepting

A `Middleware` can be setup to only intercept requests to specific handlers via the `.use(_ middleware: Middleware)` function on an `Application`. The `Middleware` will intercept all requests to the subsequently defined handlers.

```swift
app
    .post("/password_reset", handler: ...)
    // Because this middleware is provided after the /password_reset endpoint,
    // it will only affect subsequent routes. In this case, only requests to 
    // `/user` and `/todos` would be intercepted by the LoggingMiddleware.
    .use(LoggingMiddleware())
    .get("/user", handler: ...)
    .get("/todos", handler: ...)
```

There is also a `.group` function that takes a `Middleware`. The `Middleware` will _only_ intercept requests handled by handlers defined in the closure.

```swift
app
    .post("/user", handle: ...)
    .group(middleware: CustomAuthMiddleware()) {
        // Each of these endpoints will be protected by the
        // `CustomAuthMiddleWare`...
        $0.get("/todo", handler: ...)
            .put("/todo", handler: ...)
            .delete("/todo", handler: ...)
    }
    // ...but this one will not. 
    .post("/reset", handler: ...)
```

_Next page: [Papyrus](4_Papyrus.md)_

_[Table of Contents](/Docs#docs)_
