/// A type that can be injected via `@Inject`. Don't implement this directly. Instead implement one of these
/// classes that inherit from it...
/// 
///  `Singleton`: Injects a single instance.
/// `Identified`: Injects a single instance per value of a `Hashable` Identifier.
///    `Factory`: Injects a new instance each time.
public protocol Fusable {}

/// How to get this to work nicely with protocols & mocking?
/// eg....
/// protocol SomeService { ... }
/// protocol SomeServiceProvider: SomeService { ... }
/// protocol SomeServiceMock: SomeService { ... }
/// `@Inject var service: SomeService` (inject `SomeServiceProvider` normally and `SomeServiceMock` on tests).

/// TODO
/// 1. Thread Safety around container access.
