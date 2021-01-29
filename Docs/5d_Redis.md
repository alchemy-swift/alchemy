# Redis 

Redis is an open source, in-memory data structure store than can be used as a database, cache, and message broker.

Alchemy provides first class Redis support out of the box, building on the extensive [RediStack](https://github.com/Mordil/RediStack) library. 

## Connecting to Redis

You can connect to Redis using the `Redis` type. You should register this type for injection in your `Application.setup()`. For your convenience, there is a `Services.redis` wrapper around doing so. 

```swift
func setup() {
    ...
    Services.redis = Redis(.ip(host: "localhost", port: 6379))
}
```

The intializer optionally takes a password and database index (if the index isn't supplied, Redis will connect to the database at index 0, the default).

```swift
Services.redis = Redis(.ip(host: "localhost", port: 6379), password: "p@ssw0rd", database: 1)
```

### Clusters

If you're using a Redis cluster, your client can connect to multiple instances by passing multiple `Socket`s to the initializer. Connections will be distributed across the instances.

```swift
Services.redis = Redis(
    .ip("localhost", port: 6379),
    .ip("61.123.456.789", port: 6379),
    .unix("/path/to/socket")
)
```

## Interacting With Redis

`Redis` conforms to `RediStack.RedisClient` meaning that by default, it has functions around nearly all Redis commands.

You can easily get and set a value.

```swift
// Get a value.
Services.redis.get("some_key", as: String.self) // EventLoopFuture<String?>

// Set a value.
Services.redis.set("some_int", to: 42) // EventLoopFuture<Void>
```

You can also increment a value.
```swift
Services.redis.increment("my_counter") // EventLoopFuture<Int>
```

There are  convenient extensions for just about every command Redis supports. 

```swift
Services.redis.lrange(from: "some_list", indices: 0...3)
```

Alternatively, you can always run a custom command via `command`. The first argument is the command name, all subsequent arguments are the command's arguments.

```swift
Services.redis.command("lrange", "some_list", 0, 3)
```

## Transactions

If you'd like to run multiple transactions in a single, atomic operation, you may use the `.transaction(...)` function.

```swift
```

Alternatively, you can run a Lua script string via `.eval(...)`.

```swift
Services.redis.eval(
    """
    KEYS[1],KEYS[2],ARGV[1]TODODOODOD
    """, 
    keys: ["my_key", "my_counter"], 
    args: ["someValue"]
)
```

## Pub / Sub

### Wildcard Subscriptions

