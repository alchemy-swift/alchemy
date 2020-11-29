# Jobs

Right now there isn't any notion of queued jobs (backed by Redis, SQL, etc), but it's high on the priority list.

In the meantime, Alchemy provides an API for cron-like scheduling.

## Creating a job

Jobs must conform to the `Job` protocol. It has a single function `func run() -> EventLoopFuture<Void>` which performs the work to be scheduled.

```swift
struct 
****i was here****
```

## Scheduling

Often backend services need to schedule recurring work such as running various database queries or pulling external endpoints.

To do this, use `Scheduler`. It is injectable via Fusion & will likely be setup in your `Application`'s `setup` function.

You can create a block 

```swift
struct ExampleApp: Application {
    @Inject var scheduler: Scheduler
    ...

    func setup() {
        ...
        self.scheduler
            .on(.GET, at: "/hello", do: { request in "Howdy!" })
    }
}
```