# Services & Dependency Injection

- [Why Use Dependency Injection?](#why-use-dependency-injection-)
- [Registering & Resolving Services](#registering---resolving-services)
  * [Resolving with `@Inject`](#resolving-with---inject-)
  * [Cross service dependencies](#cross-service-dependencies)
  * [Optional Resolving](#optional-resolving)
- [Service Types](#service-types)
  * [Singleton Services](#singleton-services)
  * [Identified Singletons / Multitons](#identified-singletons---multitons)
- [Advanced Container Usage](#advanced-container-usage)
  * [Creating a Custom Container](#creating-a-custom-container)
  * [Creating a Child Container](#creating-a-child-container)
  * [Accessing Custom Containers from `@Inject`](#accessing-custom-containers-from---inject-)
  * [Service Automatically Registered to `Container.default`](#service-automatically-registered-to--containerglobal-)
  * [`Services`](#-services-)
- [Using Fusion in non-server targets](#using-fusion-in-non-server-targets)

Alchemy handles dependency injection using [Fusion](https://github.com/alchemy-swift/fusion). In addition, it includes a custom `Service` protocol to make it easy to inject common Alchemy such as `Database`, `Redis` and `Queue`.

## Registering and Injecting Services

Most Alchemy services conform to the `Service` protocol, which you can use to configure and access various connections.

For example, you probably want to use an SQL database in your app. You can use the `Service` methods to set up a default database driver. You'll probably want to do this in your `Application.boot`.

### Registering Defaults

Services typically have static driver functions to your configure defaults. 

```swift
Database.config(
    default: .postgres(
        host: "localhost", 
        database: "alchemy"))
```

You can now inject this database anywhere in your code via `@Inject`, and the service container will resolve the registered configuration.

```swift
@Inject var database: Database
```

You can also inject with `Database.default`. Many Alchemy APIs default to using a service's `default` so that you don't have to pass an instance in every time. For example for loading models from Rune, Alchemy's built in ORM.

```swift
struct User: Model { ... }

// Fetchs all `User` models from `Database.default`
User.all()
```

### Registering Additional Instances

If you have more than one instance of a service that you'd like to use, you can pass an identifier to the `Service.config` function to associate it with the given configuration.

```swift
Database.config(
    "mysql", 
    .mysql(
        host: "localhost", 
        database: "alchemy"))
```

This can now be injected by passing that identifier to `@Inject`.

```swift
@Inject("mysql") var mysqlDB: Database
```

It can also be inject by using the `Service.named()` function.

```swift
User.all(db: .named("mysql"))
```

## Mocking

When it comes time to write tests for your app, you can leverage the service protocol to inject mock interfaces of various services.

```swift
final class RouterTests: XCTestCase {
    private var app = TestApp()

    override func setUp() {
        super.setUp()
        Cache.config(default: .mock())
    }
}
```

_Next page: [Routing: Basics](3a_RoutingBasics.md)_

_[Table of Contents](/Docs#docs)_
