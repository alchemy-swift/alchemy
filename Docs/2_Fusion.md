# Fusion: Services & Dependency Injection

Injection
===
Alchemy uses `Fusion` to aid with dependency injection.

## Creating a Service

Fusion uses three protocol types to represent various kinds of injectible interfaces, called "Services". Conforming your services to these types allows you to inject them via the `@Inject` property wrapper anywhere in your code.

Each protocol type has a slightly different factory function that is used for creating service types when they are accssed via the `@Inject` property.

### `SingletonService`
A `SingletonService` is created once via a call to the provided `singleton(in container: Container)` function. That instance is then returned to all subsequent calls to `@Inject` using that container.

### `IdentifiedService`
`IdentifiedService` functions nearly the same as `SingletonService`, but contains an `identifier` parameter in the factory function. The factory function is run once for each separate identifier passed to it; if an instance has already been created for that identifier, it is returned.

### `FactoryService`
A `FactoryService` creates and returns a new instance of the service each time it is injected via `@Inject`.

## Injecting a Service

### `@Inject`
To inject a service into a property, you can use the `@Inject` property wrapper. The instance of the service will be resolved via the global container (`Container.global`) the first time this property is accessed.

A service can also be accessed without property wrappers through any container via `.resolve(ServiceType.self)`.

```swift
// Resolve a service from the global container. 
// 
// Equivalent to `@Inject var coolService: CoolService`.
let service = try Container.global.resolve(CoolService.self)
```

## Cross service dependencies
Sometimes, services rely on other services to function. If you need to inject services during initialization, you can resolve other services during the `factory` functions.

```swift
extension PostgresDatabase: SingletonService {
    public static func singleton(in container: Container) throws -> PostgresDatabase {
        // Load a `MultiThreadedEventLoopGroup` from the container, used to initialize the Postgres 
        // database.
        let group = try container.resolve(MultiThreadedEventLoopGroup.self)
        return PostgresDatabase(config: .postgres, eventLoopGroup: group)
    }
}
```

### Services Alchemy automatically injects into `Container.global`.
There are a few types that Alchemy automatically injects into the global container during setup. These can be used via either `@Inject` or `Container.global.resove` by any code in your app. These are described in the docs of their relevant modules, but you can find them in the Alchemy codebase by searching for extensions in  `{module}+Fusion.swift` files.

- `Router`: a global router registered for your app during setup.
- `MultiThreadedEventLoopGroup`: the `EventLoopGroup` for your app to use for getting `EventLoop`s.


_Next page: [Routing: Basics](3a_RoutingBasics.md)_

_[Table of Contents](/Docs)_