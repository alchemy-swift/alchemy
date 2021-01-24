# Fusion: Services & Dependency Injection

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
  * [Service Automatically Registered to `Container.global`](#service-automatically-registered-to--containerglobal-)
  * [`Services`](#-services-)
- [Using Fusion in non-server targets](#using-fusion-in-non-server-targets)

Alchemy uses a helper library called `Fusion` for managing dependencies and injecting them. "Dependency Injection" is a phrase that refers to "injecting" concrete implementations of abstract service types typically through initializers or properties. Fusion can also be added to non-Alchemy targets, such as iOS or macOS apps.

## Why Use Dependency Injection?

DI helps keep your code modular, testable and maintainable. It lets you define services in one place so that you may easily swap them for other implementations down the road or during tests.

## Registering & Resolving Services

"Services" (a fancy word for an abstract interface, often a protocol) are registered and resolved from `Container`s. By default there is a global container, `Container.global`, that you can use to register & resolve services from.

For example, consider an abstract type, `protocol Database`, that is implemented by a concrete type, `class PostgresDatabase: Database`. You could register the `PostgresDatabase` type to `Database` via

```swift
Container.global.register(Database.self) { _ in
    PostgresDatabase(...)
}
```

Whenever you want to access the database; you can access it through `Container.resolve`.

```swift
let database = Container.global.resolve(Database.self)
```

This makes it easy to swap out the Database for another implementation, all you'd need to do is change the register closure.

```swift
Container.global.register(Database.self) { _ in
    MySQLDatabase(...)
}
```

### Resolving with `@Inject`

You may also resolve a service with the `@Inject` property wrapper. The instance of the service will be resolved via the global container (`Container.global`) the first time this property is accessed.

```swift
@Inject var database: Database
```

### Cross service dependencies

Sometimes, services rely on other services to function. You may resolve other services from the `Container` parameter in the register closure.

```swift
Container.register(Logger.self) { ... }

Container.register(Database.self) { container in
    let logger = container.resolve(Logger.self)
    return PostgresDatabase(..., logger)
}
```

### Optional Resolving

By default, `.resolve` will `fatalError` if you try to resolve a service that isn't registered. This helps ensure that your program won't make it out of testing with you forgetting to register any services.

That being said, there may be special cases where you want to optionally resolve a service; returning `nil` if it isn't registered. For this, you may use `Container.resolveOptional`.

```swift
let optionalDatabase: Database? = Container.resolveOptional(Database.self)
```

**Note**: Optional resolving is not available when injecting via `@Inject`.

## Service Types

### Singleton Services

By default, services registered are "transient" meaning that their register closure is called each time it's resolved. 

Sometimes, you'll want only a single instance of this service being passed around (a singleton). In this case, you can use `.register(singleton:)` to register your service.

```swift
Container.global.register(singleton: Database.self) { _ in
    PostgresDatabase(...)
}
```

A singleton instance is resolved once, then cached in it's `Container` to be injected on future calls to `resolve`.

### Identified Singletons / Multitons

Sometimes you might want multiple instances of a singleton, each tied to a specific identifier (multiton / identified singleton). You can do this by passing an identifier when registering the singleton.

Perhaps you are working with two databases, one main one and one for writing logs to. You might register them like so,

```swift
enum DatabaseType: String {
    case main
    case logs
}

Container.register(singleton: Database, DatabaseType.main) { _ in
    PostgresDatabase(mainConfiguration)
}

Container.register(singleton: Database, DatabaseType.logs) { _ in
    PostgresDatabase(logConfiguration)
}
```

These can now be resolved by passing an identifier to the resolve function or the `@Inject` property wrapper.

```swift
// Via `.resolve`
let mainDB = Container.resolve(Database.self, identifier: DatabaseType.main)

// Via `@Inject`
@Inject(DatabaseType.main)
var mainDB: Database
```

## Advanced Container Usage

In many cases, only using `Container.global` will be enough for what you're trying to do. There are some cases however, where you'd like to further modularize your code with custom containers.

### Creating a Custom Container

You easily create your own containers.

```swift
let myContainer = Container()
myContainer.register(String.self) { 
    "Hello from my container!" 
}

let string = myContainer.resolve(String.self)
print(string) // "Hello from my container!"
```

**Note**: All closures and cached singletons are tied to the lifecycle of their container. When your custom container is deallocated, so will all it's closures and cached singletons.

### Creating a Child Container

You can give a container a parent container. This means that if the child container doesn't have a service registered to it, `resolving` it will attempt to register the service from the parent container.

```swift
Container.register(Int.self) {
    0
}

let childContainer = Container(parent: .global)
childContainer.register(String.self) {
    "foo"
}

// "foo"
let string = childContainer.resolve(String.self)

// 0; inherited from parent
let int = childContainer.resolve(Int.self)

// fatalError; parents do not have access to their children's services
let int = Container.global.resolve(String.self)
```

### Accessing Custom Containers from `@Inject`

By default, `@Inject` resolves services from the global container. If you'd like to inject from a custom container, you must conform the enclosing type to `Containerized`, which requires a `var container: Container { get }`.

```swift
class MyEnclosingType: Containerized {
    let container: Container

    @Inject var string: String
    @Inject var int: Int

    init(container: Container) {
        self.container = container
    }
}

let container = Container()
container.register(String.self) { "Howdy" }
container.register(Int.self) { 42 }

let myType = MyEnclosingType(container: container)
print(myType.string) // "Howdy"
print(myType.int) // 42
```

### Services Automatically Registered to `Container.global`

There are a few types to be aware of that Alchemy automatically injects into the global container during setup. These can be accessed via `@Inject` or `Container.resolve` anywhere in your app.

- `Router`: the router that will handle all incoming requests.
- `EventLoopGroup`: the group of `EventLoop`s to which your application runs requests on.

### `Services`

`Alchemy` contains a `Services` type providing convenient static variables for injecting commonly used services from the global container.

```swift
let scheduler = Services.scheduler
let eventLoopGroup = Services.eventLoopGroup
```

You may also add custom static properties to it at your own convenience:
```swift
extension Services {
    static var someType: SomeType {
        Container.global.resolve(SomeType.self)
    }
}
```

**Note**: Many `QueryBuilder` & `Rune ORM` APIs default to running queries on `Services.db`. Be sure to register a singleton global database in your `Application.setup` to use them.

**Other Note**: You can mock many of these common services in tests by calling `Services.mock()` in your test case `setUp()`.

```swift
// In Application.setup

Container.register(singleton: Database.self) { _ in
    PostgresDatabase(...)
}
```

## Using Fusion in non-server targets

When you `import Alchemy`, you automatically import Fusion. If you'd like to use Fusion in a non-server target, you can add `Fusion` as a dependency through SPM and import it via `import Fusion`.

_Next page: [Routing: Basics](3a_RoutingBasics.md)_

_[Table of Contents](/Docs#docs)_
