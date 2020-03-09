/// How to get this to work nicely with protocols?
/// eg....
/// protocol SomeService { ... }
/// protocol SomeServiceProvider: SomeService { ... }
/// protocol SomeServiceMock: SomeService { ... }
protocol Injectable {
    static var shouldMock: Bool { get }
    static func create(_ isMock: Bool) -> Self
}

@propertyWrapper
struct Inject<Value: Injectable> {

    var wrappedValue: Value {
        get {
//            if Value.shouldMock {
//
//            }
            fatalError()
        }
    }
    // Use cases
    // 1. A singleton, i.e. a redis cache.
    // 2. One of a few, i.e. there are multiple databases.
    // 3. Varies on the fly, i.e. a specific ViewModel.
}

extension Injectable {
    static var shouldMock: Bool { true }
}

/// Scratch
protocol SomeService {
    func doStuff()
    func doOtherStuff()
}

struct SomeServiceProvider: SomeService {
    func doStuff() { print("do stuff") }
    func doOtherStuff() { print("do other stuff") }
}

struct SomeServiceMock: SomeService {
    func doStuff() { print("mock stuff") }
    func doOtherStuff() { print("mock other stuff") }
}
