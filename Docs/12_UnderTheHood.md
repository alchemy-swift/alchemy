# Under the Hood

- [Event Loops and You](#event-loops-and-you)
  * [Caveat 1: Don't block EventLoops!](#caveat-1-dont-block-eventloops)
  * [Caveat 2: Use non-blocking APIs (EventLoopFuture)](#caveat-2-use-non-blocking-apis-eventloopfuture-when-doing-async-tasks)
    + [Creating a new EventLoopFuture](#creating-a-new-eventloopfuture)
  * [Accessing EventLoops or EventLoopGroups](#accessing-eventloops-or-eventloopgroups)

Alchemy is built on top of [Swift NIO](https://github.com/apple/swift-nio) which provides an "event driven architecture". This means that each request your server handles is assigned/run on an "event loop", a thread designated for handling incoming requests (represented by the `NIO.EventLoop` type).

## Event Loops and You

There are as many unique `EventLoop`s as there are logical cores on your machine, and as requests come in, they are distributed between them. For the most part, logic around `EventLoop`s is abstracted away for you, but there are a few caveats to be aware of when building with Alchemy.

### Caveat 1: **Don't block `EventLoop`s!**

The faster you finish handling a request, the sooner the `EventLoop` it's running on will be able to handle additional requests. To keep your server fast, don't block the event loops on which your router handlers are run. If you need to do some CPU intensive work, spin up another thread with `Thread.run`. This will allow the `EventLoop` of the request to handle other work while your intesive task is being completed on another thread. When the task is done, it will hop back to it's original `EventLoop` where it's handling can be finished.

### Caveat 2: **Use non-blocking APIs (`EventLoopFuture`) when doing async tasks**

Often, handling a request involves waiting for other servers / services to do something. This could include making a database query or making an external HTTP request. So that EventLoop threads aren't blocked, Alchemy leverages `EventLoopFuture`. `EventLoopFuture<T>` is the Swift server world's version of a `Future`. It represents an asynchronous operation that hasn't yet completed, but will complete on a specific `EventLoop` with either an `Error` or a value of `T`.

If you've worked with other future types before, these should be straighforward; the API reference is [here](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html). If you haven't, think of them as functional sugar around a value that you'll get in the future (i.e. is being fetched asynchronously). You can chain functions that change the value (`.map { ... }`) or change the value asynchronously (`.flatMap { ... }`) and then respond to the value (or an error) when it's finally resolved.

#### Creating a new `EventLoopFuture`

If needed, you can easily create a new future associated with the current `EventLoop` via `EventLoopFuture<SomeType>.new(error:)` or `EventLoopFuture<SomeType>.new(_ value:)`. These will resolve immediately on the current `EventLoop` with the value or error passed to them.

```swift
func someHandler() -> EventLoopFuture<String> {
    .new("Hello!")
}

func unimplementedHandler() -> EventLoopFuture<String> {
    .new(error: HTTPError(.notImplemented, message: "This endpoint isn't implemented yet"))
}
```

### Accessing `EventLoop`s or `EventLoopGroup`s

In general, you won't need to access or think about any `EventLoop`s, but if you do, you can get the current one with `Loop.current`. 

```swift
let thisLoop: EventLoop = Loop.current
```

Should you need an `EventLoopGroup` for other `NIO` based libraries, you can access the global `EventLoopGroup` (a `MultiThreadedEventLoopGroup`) via `Loop.group`.

```swift
let appLoopGroup: EventLoopGroup = Loop.group
```

Finally, should you need to run an expensive operation, you may use `Thread.run` which uses an entirely separate thread pool instead of blocking any of your app's `EventLoop`s.

_[Table of Contents](/Docs#docs)_
