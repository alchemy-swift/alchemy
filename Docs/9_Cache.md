# Cache

- [Configuration](#configuration)
- [Interacting with the Cache](#interacting-with-the-cache)
  * [Storing Items in the Cache](#storing-items-in-the-cache)
    + [Storing Custom Types](#storing-custom-types)
  * [Retreiving Cache Items](#retreiving-cache-items)
    + [Checking for item existence](#checking-for-item-existence)
    + [Incrementing and Decrementing items](#incrementing-and-decrementing-items)
  * [Removing Items from the Cache](#removing-items-from-the-cache)
- [Adding a Custom Cache Provider](#adding-a-custom-cache-provider)

You'll often want to cache the results of expensive or long running operations to save CPU time and respond to future requests faster. Alchemy provides a `Cache` type for easily interacting with common caching backends.

## Configuration

Cache conforms to `Service` and can be configured like other Alchemy services with the `config` function. Out of the box, providers are provided for Redis and SQL based caches as well as an in memory mock cache.

```swift
Cache.config(default: .redis())
```

If you're using the `Cache.sql()` cache configuration, you'll need to add the `Cache.AddCacheMigration` migration to your database's migrations.

```swift
Database.default.migrations = [
    Cache.AddCacheMigration(),
    ...
]
```

## Interacting with the Cache

### Storing Items in the Cache

You can store values to the cache using the `set()` function.

```swift
cache.set("num_unique_users", 62, for: .seconds(60))
```

The third parameter is optional and if not passed the value will be stored indefinitely.

#### Storing Custom Types

You can store any type that conforms to `CacheAllowed` in a cache. Out of the box, `Bool`, `String`, `Int`, and `Double` are supported, but you can easily store your own types as well.

```swift
extension URL: CacheAllowed {
    public var stringValue: String {
        return absoluteString
    }
    
    public init?(_ string: String) {
        self.init(string: string)
    }
}
```

### Retreiving Cache Items

Once set, a value can be retrived using `get()`.

```swift
cache.get("num_unique_users")
```

#### Checking for item existence

You can check if a cache contains a specific item using `has()`.

```swift
cache.has("\(user.id)_last_login")
```

#### Incrementing and Decrementing items

When working with numerical cache values, you can use `increment()` and `decrement()`.

```swift
cache.increment("key")
cache.increment("key", by: 4)
cache.decrement("key")
cache.decrement("key", by: 4)
```

### Removing Items from the Cache

You can use `delete()` to clear an item from the cache.

```swift
cache.delete(key)
```

Using `remove()`, you can clear and return a cache item.

```swift
let value = cache.remove(key)
```

If you'd like to clear all data from a cache, you may use wipe.

```swift
cache.wipe()
```

## Adding a Custom Cache Provider

If you'd like to add a custom provider for cache, you can implement the `CacheProvider` protocol.

```swift
struct MemcachedCache: CacheProvider {
    func get<L: LosslessStringConvertible>(_ key: String) -> EventLoopFuture<C?> {
        ...
    }
    
    func set<L: LosslessStringConvertible>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> {
        ...
    }

    func has(_ key: String) -> EventLoopFuture<Bool> {
        ...
    }

    func remove<L: LosslessStringConvertible>(_ key: String) -> EventLoopFuture<C?> {
        ...
    }

    func delete(_ key: String) -> EventLoopFuture<Void> {
        ...
    }

    func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        ...
    }

    func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        ...
    }

    func wipe() -> EventLoopFuture<Void> {
        ...
    }
}
```

Then, add a static configuration function for using your new cache backend.

```swift
extension Cache {
    static func memcached() -> Cache {
        Cache(MemcachedCache())
    }
}

Cache.config(default: .memcached())
```

_Next page: [Commands](13_Commands.md)_

_[Table of Contents](/Docs#docs)_
