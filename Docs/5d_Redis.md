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

## Scripting

You can run a script via `.eval(...)`. 

Scripts are written in Lua and have access to 1-based arrays `KEYS` and `ARGV` for accessing keys and arguments respectively. They also have access to a `redis` variable for calling Redis inside the script. Consult the [EVAL documentation](https://redis.io/commands/eval) for more information on scripting. 

```swift
Services.redis.eval(
    """
    local counter = redis.call("incr", KEYS[1])

    if counter > 5 then
        redis.call("incr", KEYS[2])
    end

    return counter
    """,
    keys: ["key1", "key2"]
)
```

## Pub / Sub

Redis provides `publish` and `subscribe` commands to publish and listen to various channels. 

You can easily subscribe to a single channel or multiple channels.

```swift
Services.redis
    .subscribe(to: "my-channel") { value in
        print("my-channel got: \(value)")
    }
    
Services.redis
    .subscribe(to: ["my-channel", "other-channel"]) { channelName, value in
        print("\(channelName) got: \(value)")
    }
```

Publishing to them is just as simple.

```swift
Services.redis
    .publish("hello", to: "my-channel")
```

If you want to stop listening to a channel, use `unsubscribe`.

```swift
Services.redis.unsubscribe(from: "my-channel")
```

### Wildcard Subscriptions

You may subscribe to wildcard channels using `psubscribe`. 

```swift
Services.redis
    .psubscribe(to: ["*"]) { channelName, value in
        print("\(channelName) got: \(value)")
    }
    
Services.redis
    .psubscribe(to: ["subscriptions.*"]) { channelName, value in
        print("\(channelName) got: \(value)")
    }
```

Unsubscribe with `punsubscribe`.

```swift
Services.redis.punsubscribe(from: "*")
```
