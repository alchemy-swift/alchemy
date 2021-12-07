# Queues

- [Configuring Queues](#configuring-queues)
- [Creating Jobs](#creating-jobs)
- [Dispatching Jobs](#dispatching-jobs)
- [Dequeuing and Running Jobs](#dequeuing-and-running-jobs)
- [Channels](#channels)
- [Handling Job Failures](#handling-job-failures)

Often your app will have long running operations, such as sending emails or reading files, that take too long to run during a client request. To help with this, Alchemy makes it easy to create queued jobs that can be persisted and run in the background. Your requests will stay lightning fast and important long running operations will never be lost if your server restarts or re-deploys.

Configure your queues with the `Queue` class. Out of the box, Alchemy provides providers for queues backed by Redis and SQL as well as an in-memory mock queue.

## Configuring Queues

Like other Alchemy services, Queue conforms to the `Service` protocol. Configure it with the `config` function.

```swift
Queue.config(default: .redis())
```

If you're using the `database()` queue configuration, you'll need to add the `Queue.AddJobsMigration` migration to your database's migrations.

```swift
Database.default.migrations = [
    Queue.AddJobsMigration(),
    ...
]
```

## Creating Jobs

To make a task to run on a queue, conform to the `Job` protocol. It includes a single `run` function. It also requires `Codable` conformance, so that any properties will be serialized and available when the job is run.

```swift
struct SendWelcomeEmail: Job {
    let email: String

    func run() -> EventLoopFuture<Void> {
        // Send welcome email to email
    }
}
```

Note that Rune `Model`s are Codable and can thus be included and persisted as properties of a job.


```swift
struct ProcessUserTransactions: Job {
    let user: User

    func run() -> EventLoopFuture<Void> {
        // Process user's daily transactions
    }
}
```

## Dispatching Jobs

Dispatching a job is as simple as calling `dispatch()`.

```swift
SendWelcomeEmail(email: "josh@withapollo.com").dispatch()
```

By default, Alchemy will dispatch your job on the default queue. If you'd like to run on a different queue, you may specify it.

```swift
ProcessUserTransactions(user: user)
    .dispatch(on: .named("other_queue"))
```

If you'd like to run something when your job is complete, you may override the `finished` function to hook into the result of a completed job.

```swift
struct SendWelcomeEmail: Job {
    let email: String

    func run() -> EventLoopFuture<Void> { ... }

    func finished(result: Result<Void, Error>) {
        switch result {
        case .success:
            Log.info("Successfully sent welcome email to \(email).")
        case .failure(let error):
            Log.error("Failed to send welcome email to \(email). Error was: \(error).")
        }
    }
}
```

## Dequeuing and Running Jobs

To actually have your jobs run after dispatching them to a queue, you'll need to run workers that monitor your various queues for work to be done.

You can spin up workers as a separate process using the `queue` command.

```bash
swift run MyApp queues
```

If you don't want to manage another running process, you can pass the `--workers` flag when starting your server have it run the given amount of workers in process.

```swift
swift run MyApp --workers 2
```

You can view the various options for the `queues` command in [Configuration](1_Configuration.md#queue).

## Channels

Sometimes you may want to prioritize running some jobs over others or have workers that only run certain kinds of jobs. Alchemy provides the concept of a "channel" to help you do so. By default, jobs run on the "default" channel, but you can specify the specific channel name to run on with the channel parameter in `dispatch()`.

```swift
SendPasswordReset(for: user).dispatch(channel: "email")
```

By default, a worker will dequeue jobs from a queue's `"default"` channel, but you can tell them dequeue from another channel with the -c option.

```shell
swift run MyServer queue -c email
```

You can also have them dequeue from multiple channels by separating channel names with commas. It will prioritize jobs from the first channels over subsequent ones.

```shell
swift run MyServer queues -c email,sms,push
```

## Handling Job Failures

By default, jobs that encounter an error during execution will not be retried. If you'd like to retry jobs on failure, you can add the `recoveryStrategy` property. This indicates what should happen when a job is failed.

```swift
struct SyncSubscriptions: Job {
    // Retry this job up to five times.
    var recoveryStrategy: RecoveryStrategy = .retry(5)
}
```

You can also specify the `retryBackoff` to wait the specified time amount before retrying a job.

```swift
struct SyncSubscriptions: Job {
    // After a job failure, wait 1 minute before retrying
    var retryBackoff: TimeAmount = .minutes(1)
}
```

_Next page: [Cache](9_Cache.md)_

_[Table of Contents](/Docs#docs)_
