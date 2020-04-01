/// How to get this to work nicely with protocols?
/// eg....
/// protocol SomeService { ... }
/// protocol SomeServiceProvider: SomeService { ... }
/// protocol SomeServiceMock: SomeService { ... }
public protocol Injectable {
    static var shouldMock: Bool { get }
    static func create(_ isMock: Bool) -> Self
}

@propertyWrapper
public struct Inject<Value: Injectable> {

    public var wrappedValue: Value {
        get {
//            if Value.shouldMock {
//
//            }
            fatalError()
        }
    }
    
    public init() {}
    
    // Use cases
    // 1. A singleton, i.e. a redis cache.
    // 2. One of a few, i.e. there are multiple databases.
    // 3. Varies on the fly, i.e. a specific ViewModel.
}

extension Injectable {
    public static var shouldMock: Bool { true }
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
