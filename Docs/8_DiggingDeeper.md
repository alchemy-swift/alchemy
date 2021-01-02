# Digging Deeper

# Jobs

Right now there isn't any notion of queued jobs (backed by Redis, SQL, etc), but it's high on the priority list.

In the meantime, Alchemy provides an API for cron-like scheduling.

## Creating a job

Jobs must conform to the `Job` protocol. It has a single function `func run() -> EventLoopFuture<Void>` which performs the work to be scheduled.

```swift
struct BackupDatabase: Job {
    func run() -> EventLoopFuture<Void> {
        ...
    }
}
```

## Scheduling

Often backend services need to schedule recurring work such as running various database queries or pulling external endpoints.

To do this, use `Scheduler`. It is injectable via Fusion & will likely be setup in your `Application`'s `setup` function.

```swift
struct ExampleApp: Application {
    @Inject var scheduler: Scheduler
    ...

    func setup() {
        ...
        self.scheduler
            // The scheduler will fire the `run` function on the BackupDatabase
            // job every day @ 12am.
            .schedule(BackupDatabase(), every: 1.days)
    }
}
```

## Schedule frequencies

To aid in fine tuning when your scheduled Jobs run, Alchemy provides some extensions on `Int` to pass to the `every` parameter.

Note that calls to `scheduele` can be chained for readability.

```swift
scheduler
    // Runs every day @ midnight.
    .schedule(BackupDatabase(), every: 1.days)
    // Runs every day @ 9:30am.
    .schedule(EmailNewUsers(), every: 1.days.at(hr: 9, min: 30))
    // Runs every hour @ X:00:00.
    .schedule(SlackAPIStatus(), every: 1.hour)
    // Runs every minute @ X:XX:30.
    .schedule(CheckAPIStatus(), every: 1.minutes.at(sec: 30))
```

# Logging

To aid with logging, Alchemy provides a thin wrapper on top of `swift-log`.

You can conveniently log to the various levels via the `Log` struct.

```swift
Log.trace("Here")
Log.debug("Testing")
Log.info("Hello")
Log.notice("FYI")
Log.warning("Hmmm")
Log.error("Uh oh")
Log.critical("Houston, we have a problem")
```

_[Table of Contents](/Docs)_