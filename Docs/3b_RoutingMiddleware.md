# Routing: Middleware

## Creating Middleware

A middleware is a piece of code that is run before or after a request is handled. It might modify the `Request` or `Response`.

In Alchemy, a middleware is created by conforming to the `Middleware` protocol. It has a single function `intercept` which takes a `Request` and `next` closure. It returns an `EventLoopFuture<Response>`.

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

You can also do something with the request asynchronously, just be sure to continue the chain with `next(req)` when you are finished.

```swift
/// Runs a database query before passing a request to a handler.
struct QueryingMiddleware: Middleware {
    @Inject db: Database

    func intercept(_ request: Request, next: @escaping Next) -> EventLoopFuture<Response> {
        return self.db.query()
            ...
            .getAll(...)
            .flatMap { queryResults in 
                // handle the query results
                // continue the handler chain
                next(request)
            }
    }
}
```

### Setting Data on a Request

Sometimes you may want a `Middleware` to add some data to a `Request`. For example, you may want to authenticate an incoming request with a `Middleware` and then add a `User` to it for handlers down the chain to access. 

You can set generic data on a `Request` using `Request.set` and then access it in subsequent `Middleware` or handlers via `Request.get`.

For example, you might be doing some experiments with a homegrown `ExperimentConfig` type. You'd like to assing random configurations of that type on a per-request basis. You might do so with a `Middleware`:

```swift
struct ExperimentMiddleware: Middleware {
    func intercept(_ request: Request, next: @escaping Next) -> EventLoopFuture<Response> {
        let config: ExperimentConfig = ... // load a random experiment config
        return next(request.set(config))
    }
}
```

You would then intercept requests with that `Middleware` and utilize the set `ExperimnetConfig` in your handlers.

```swift
router
    .middleware(ExperimentalMiddleware())
    .on(.GET, "/experimental_endpoint") { request in
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

## Setting Middleware on a Router

There are a few ways to have a `Middleware` intercept requests.

### Global Intercepting

If you'd like a middleware to intercept _all_ requests on a `Router`, you can add it to `Router.globalMiddlewares`.

```swift
struct ExampleApp: Application {
    @Inject var router: HTTPRouter

    func setup() {
        self.router.globalMiddlewares = [
            // Will intercept all `Request`s on this `Router`.
            LoggingMiddleware()
        ]
        
        self.router
            // LoggingMiddleware will intercept all of these, as well as any unhandled requests.
            .on(.GET, at: "/foo", do: { request in "Howdy foo!" })
            .on(.POST, at: "/bar", do: { request in "Howdy bar!" })
            .on(.PUT, at: "/baz", do: { request in "Howdy baz!" })
    }
}
```

### Specific Intercepting

A `Middleware` can be setup to only intercept requests to specific handlers via the `.middleware(_ middleware: Middleware)` function on a `Router`. This function will return a new child router & the `Middleware` will be applied to all handlers added on that child `Router`.

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

_Next page: [Papyrus](4_Papyrus.md)_

_[Table of Contents](/Docs)_