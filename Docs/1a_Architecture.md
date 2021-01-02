# Architecture

Alchemy is built on top of [Swift NIO](https://github.com/apple/swift-nio) which provides an "event driven architecture". This means that each request your server handles is assigned/run on an "event loop", essentially a thread which incoming requests are handled on (represented by the `NIO.EventLoop` type).

## Event Loops and You

There are as many unique `EventLoop`s as there are logical cores on your machine, and as requests come in, they are distrubuted between them. For the most part, logic around `EventLoop`s is abstracted away for you, but there are a few caveats to be aware of when building with Alchemy.

### Caveat 1: **Don't block `EventLoop`s!**

The faster you finish handling a request, the sooner the `EventLoop` it's running on will be able to handle additional requests. To keep your server fast, don't block the threads on which your router handlers are run. If you need to do some CPU intensive work, spin up another thread with `Thread.run`. This will allow the `EventLoop` of that request to handle other work while your intesive task is done. When the task is done, it will hop back to the `EventLoop` the request is running on to finish handling it.

### Caveat 2: **Use non-blocking APIs (`EventLoopFuture`) when doing async tasks**

Often, handling a request involves waiting for other servers / services to do something such as making a database query or making an external HTTP request. So as not to block event loops, Alchemy leverages `EventLoopFuture`. `EventLoopFuture<T>` is the Swift server world's version of a `Future`. It represents an asynchronous operation that hasn't yet completed, but will complete on a specific `EventLoop` with either an `Error` or a value of `T`.

If you've worked with other future types or `RxSwift` before, these should be straighforward; the API reference is [here](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html). If you haven't, think of them as functional sugar around a value that you'll get in the future (i.e. is being fetched asynchronously). You can chain functions that change the value (`.map { ... }`) or change the value asynchronously (`.flatMap { ... }`) and then respond to the value (or an error) when it's finally resolved.

#### Creating a new `EventLoopFuture`

If needed, you can easily create a new future associated with the current `EventLoop` via `EventLoopFuture<SomeType>.new(error:)` or `EventLoopFuture<SomeType>.new(_ value:)`. These will resolve immediately on the current `EventLoop` with the value or error passed to them.

```swift
func someHandler() -> EventLoopFuture<String> {
    .new("Hello!")
}

func unimplementedHandler() -> EventLoopFuture<String> {
    .new(error: HTTPError(.notImplemented, "This endpoint isn't implemented yet"))
}
```

### Accessing `EventLoop`s or `EventLoopGroup`s

In general, you won't need to access or think about any `EventLoop`s, but if you do, you can get the current one with `Loop.current`. 

```swift
let thisLoop: EventLoop = Loop.current
```

Should you need an `EventLoopGroup` for other `NIO` based libraries, you can access the global `MultiThreadedEventLoopGroup` via `Container.resolve(EventLoopGroup.self)`.

```swift
let globalGroup: EventLoopGroup = Container.resolve(EventLoopGroup.self)
```

_Up next: [Configuration](1b_Configuration.md)_

_[Table of Contents](/Docs)_